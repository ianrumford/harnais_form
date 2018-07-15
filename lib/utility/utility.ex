defmodule Harnais.Form.Utility do
  @moduledoc false

  require Plymio.Fontais.Option
  use Plymio.Fontais.Attribute
  use Harnais.Error.Attribute
  use Harnais.Form.Attribute

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Utility,
    only: [
      list_wrap_flat_just: 1
    ]

  import Plymio.Fontais.Option,
    only: [
      opts_validate: 1,
      opts_normalise: 1,
      opts_create_aliases_dict: 1,
      opts_canonical_keys: 2
    ]

  import Plymio.Fontais.Form,
    only: [
      forms_reduce: 1,
      form_validate: 1
    ]

  import Plymio.Funcio.Enum.Map.Collate,
    only: [
      map_collate0_enum: 2
    ]

  @type ast :: Harnais.ast()
  @type asts :: Harnais.asts()
  @type form :: Harnais.ast()
  @type forms :: Harnais.asts()
  @type opts :: Harnais.opts()
  @type error :: Harnais.error()

  @harnais_form_dict_opts_transform_form_aliases @harnais_form_aliases_opts_transform_ast
                                                 |> opts_create_aliases_dict

  @harnais_form_keys_opts_transform_ast_aliases @harnais_form_dict_opts_transform_form_aliases
                                                |> Map.keys()

  # the aliases for harnais_form_test_forms include keys for harnais_form_transform
  @harnais_form_dict_ast_eval_aliases (@harnais_form_aliases_opts_transform_ast ++
                                         [
                                           {@harnais_form_key_transform_opts, nil},
                                           {@harnais_form_key_eval_opts, nil},
                                           {@harnais_form_key_eval_binding, [:binding]}
                                         ])
                                      |> opts_create_aliases_dict

  def opts_ast_eval_canonical_keys(opts, dict \\ @harnais_form_dict_ast_eval_aliases) do
    opts |> opts_canonical_keys(dict)
  end

  def opts_ast_transform_canon_keys(opts, dict \\ @harnais_form_dict_opts_transform_form_aliases) do
    opts |> opts_canonical_keys(dict)
  end

  def opts_ast_transform_keys_aliases do
    @harnais_form_keys_opts_transform_ast_aliases
  end

  @spec forms_validate(any) :: {:ok, forms} | {:error, error}

  def forms_validate(forms)

  def forms_validate([form]) do
    with {:ok, _} <- form |> form_validate do
      {:ok, [form]}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def forms_validate(forms) when is_list(forms) do
    forms
    |> Stream.with_index()
    |> Enum.reduce(
      [],
      fn {form, index}, invalid_indices ->
        case form |> form_validate do
          {:ok, _} -> invalid_indices
          {:error, _} -> [index | invalid_indices]
        end
      end
    )
    |> case do
      # no invalid forms
      [] ->
        {:ok, forms}

      invalid_indices ->
        new_error_result(
          m: "forms invalid, got invalid indices: #{inspect(Enum.reverse(invalid_indices))}"
        )
    end
  end

  def forms_validate(forms) do
    new_error_result(m: "forms invalid", v: forms)
  end

  @spec forms_normalise(any) :: {:ok, forms} | {:error, error}

  def forms_normalise(forms \\ [])

  def forms_normalise(forms) do
    forms
    |> list_wrap_flat_just
    |> Enum.reject(fn
      # empty block
      {:__block__, _, []} ->
        true

      _ ->
        false
    end)
    |> forms_validate
    |> case do
      {:ok, _} = result -> result
      {:error, %{__struct__: _}} = result -> result
    end
  end

  @spec form_eval(any, any) :: {:ok, form} | {:error, error}

  def form_eval(form, opts \\ [])

  def form_eval(form, opts) do
    with {:ok, opts} <- opts |> opts_normalise,
         {:ok, forms} <- form |> List.wrap() |> forms_validate,
         {:ok, eval_form} <- forms |> forms_reduce do
      with {:ok, eval_binding} <- Keyword.get(opts, :eval_binding) |> opts_validate,
           {:ok, eval_opts} <- Keyword.get(opts, :eval_opts, []) |> opts_validate do
        eval_form =
          eval_form
          |> Macro.postwalk(fn
            {n, [], m} when is_atom(n) and is_atom(m) -> n |> Macro.var(nil)
            x -> x
          end)

        # eval_form

        try do
          eval_form
          |> Code.eval_quoted(eval_binding, eval_opts)
          |> case do
            {result, _} ->
              {:ok, {result, form}}

            _ ->
              new_error_result(m: "form eval failed", v: eval_form)
          end
        catch
          _ -> new_error_result(m: "eval failed", v: eval_form)
        end
      else
        _ -> new_error_result(m: "eval binding or opts invalid", v: opts)
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def form_format(form, opts \\ [])

  def form_format(form, opts) when is_binary(form) do
    with {:ok, opts} <- opts |> opts_validate do
      text =
        form
        |> Code.format_string!(opts)
        |> Enum.join()

      {:ok, text}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def form_format(form, opts) do
    with {:ok, form} <- form |> forms_reduce,
         text <- form |> Macro.to_string(),
         {:ok, _text} = result <- text |> form_format(opts) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def forms_format(forms, opts \\ [])

  def forms_format(forms, opts) do
    with {:ok, forms} <- forms |> forms_normalise do
      forms |> map_collate0_enum(fn form -> form |> form_format(opts) end)
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @code_edits_beg [
    # reduce multiple spaces
    {~r/\h+/, " "},

    # dump too many leading or trailing space after \n
    {~r/\A\n\s\s*/s, "\n "},
    {~r/\n\s+\z/s, "\n"}
  ]

  @code_edits_mid []

  @code_edits_fin [
    {~r/\-\>\n/, "-> "},
    {~r/\n\|\>/, " |>"},

    # dump too many leading or trailing space after brakets
    {~r/\(\s+/, "("},
    {~r/\s+\)/, ")"},

    # dump too many leading or trailing space after \n
    {~r/\A\s+/, ""},
    {~r/\n\s+\z/s, "\n"},

    # tidy front
    {~r/\A\(\s+/s, "("},

    # tidy back
    {~r/\s+\)\z/s, ")"}
  ]

  # this is a sequence of apply calls
  # the current code will be prepended to the args
  @edit_text_pipeline_default [
    {__MODULE__, :textify_form_edit_text_with_regex,
     [[{@harnais_form_opts_key_edit_regex, @code_edits_beg}]]},
    {String, :split, ["\n"]},
    {Enum, :map, [&String.trim/1]},
    {__MODULE__, :textify_form_edit_texts_with_regex,
     [[{@harnais_form_opts_key_edit_regex, @code_edits_mid}]]},
    {Enum, :reject, [&Harnais.Utility.string_empty?/1]},
    {Enum, :join, ["\n "]},
    {__MODULE__, :textify_form_edit_text_with_regex,
     [[{@harnais_form_opts_key_edit_regex, @code_edits_fin}]]}
  ]

  @doc false
  def textify_form_edit_text_with_regex(text, opts \\ []) do
    opts
    |> Keyword.fetch!(@harnais_form_opts_key_edit_regex)
    |> Enum.reduce(
      text,
      fn {r, v}, t ->
        Regex.replace(r, t, v)
      end
    )
  end

  @doc false
  def textify_form_edit_texts_with_regex(texts, opts \\ []) do
    texts
    |> list_wrap_flat_just
    |> Enum.map(fn t ->
      t |> textify_form_edit_text_with_regex(opts)
    end)
  end

  @doc false
  def textify_form_edit_text_with_pipeline(text, opts \\ []) when is_binary(text) do
    opts
    |> Keyword.get(@harnais_form_opts_key_edit_pipeline, @edit_text_pipeline_default)
    |> Enum.reduce(
      text,
      fn {m, f, a}, t ->
        apply(m, f, [t | a])
      end
    )
  end

  @doc false
  def textify_form_edit_texts_with_pipeline(texts, opts \\ []) do
    texts
    |> list_wrap_flat_just
    |> Enum.map(fn t ->
      t |> textify_form_edit_text_with_pipeline(opts)
    end)
  end

  @doc false
  defp textify_form_worker(code, opts \\ [])

  defp textify_form_worker(value, _opts)
       when is_number(value) or is_atom(value) or is_float(value) do
    value
    |> inspect
  end

  defp textify_form_worker(code, opts) when is_list(code) do
    code
    |> Enum.map(&textify_form_worker/1)
    |> Enum.join("\n")
    |> textify_form_worker(opts)
  end

  defp textify_form_worker(code, opts) when is_tuple(code) do
    code
    |> Macro.to_string()
    |> textify_form_worker(opts)
  end

  defp textify_form_worker(code, opts) when is_binary(code) do
    code
    |> textify_form_edit_text_with_pipeline(opts)
  end

  defp textify_form_worker(code, opts) do
    with {:ok, form} <- code |> form_validate do
      form
      |> Macro.to_string()
      |> textify_form_worker(opts)
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def textify_form(code, opts \\ [])

  def textify_form(code, opts) do
    code
    |> textify_form_worker(opts)
    |> case do
      text when is_binary(text) -> {:ok, text}
      {:ok, text} when is_binary(text) -> {:ok, text}
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `truthy0_result/1` takes an argument an enforces *pattern 0* *truthiness".

   If the argumnet is `{:ok, any}` or `{:error, error}`, it is rteurned unchanged.

   If the argument is `true`, `{:ok, true}` is returned.

   Any other argument will return `{:error, match_error}` where
   `match_error` is a `MatchError` with the `term` set to the
   argument.

   ## Examples

      iex> {:ok, 42} |> truthy0_result
      {:ok, 42}

      iex> {:error, %ArgumentError{message: "value is 42"}} |> truthy0_result
      {:error, %ArgumentError{message: "value is 42"}}

      iex> true |> truthy0_result
      {:ok, true}

      iex> false |> truthy0_result
      {:error, %MatchError{term: false}}

      iex> nil |> truthy0_result
      {:error, %MatchError{term: nil}}

      iex> 42 |> truthy0_result
      {:error, %MatchError{term: 42}}
  """

  @since "0.1.0"

  @spec truthy0_result(any) :: {:ok, any} | {:error, error}

  def truthy0_result(result)

  def truthy0_result(result)
      when result in [nil, false] do
    {:error, %MatchError{term: result}}
  end

  def truthy0_result(result)
      when result in [true] do
    {:ok, result}
  end

  def truthy0_result({:ok, _} = result) do
    result
  end

  def truthy0_result({:error, %{__struct__: _}} = result) do
    result
  end

  def truthy0_result(result) do
    {:error, %MatchError{term: result}}
  end
end
