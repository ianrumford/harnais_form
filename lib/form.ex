defmodule Harnais.Form do
  @moduledoc ~S"""
  Functions for Testing Quoted Forms

  ## Documentation Terms

  In the documentation these terms, usually in *italics*, are used to mean the same thing.

  ### *form* and *forms*

  A *form* is a quoted form (`Macro.t`). A *forms* is a list of zero, one or more *form*s

  ### *opts*

  An *opts* is a `Keyword` list.

  ## Bang and Query Functions

  All functions have a bang peer.

  `harnais_form/1`, `harnais_forms/1` and all compare functions
  (e.g. `harnais_form_compare/3`) have a query peer
  (e.g. `harnais_form_compare?/3`).

  These functions do not appear in the function list to stop clutter. (They are `@doc false`).
  """

  use Plymio.Codi
  alias Harnais.Error, as: HEE
  alias Harnais.Form.Schatten, as: HAS
  alias Harnais.List, as: HUL
  use Harnais.Error.Attribute
  use Harnais.Form.Attribute
  use Harnais.Form.Attribute.Schatten

  @codi_opts [
    {@plymio_codi_key_vekil, Plymio.Vekil.Codi.__vekil__()}
  ]

  import Plymio.Fontais.Option,
    only: [
      opts_normalise: 1,
      opts_validate: 1
    ]

  import Plymio.Fontais.Form,
    only: [
      forms_edit: 2
    ]

  @type ast :: Harnais.ast()
  @type asts :: Harnais.asts()
  @type form :: Harnais.form()
  @type forms :: Harnais.forms()
  @type opts :: Harnais.opts()
  @type error :: Harnais.error()

  @harnais_form_message_text_form_compare_failed "form compare failed"

  @doc ~S"""
  `harnais_form_test_forms/2` takes a *forms* with optional
  *opts* and evaluate the *forms*, after processing any
  options.

  It returns `{:ok, {answer, forms}}` if evaluation succeeds, else
  `{:error, error}`.

  The `forms` in the result will be the form after any transformed have
  been applied.

  > This function calls `Harnais.Form.Schatten.produce_schatten/2` with common options prepended to any supplied *opts*. Its documentation should be read to understand the production process and allowed options.

  ## Examples

      iex> harnais_form_test_forms(42)
      {:ok, {42, 42}}

      iex> quote(do: x = 42) |> harnais_form_test_forms
      {:ok, {42, quote(do: x = 42)}}

      iex> quote(do: x = 42) |> harnais_form_test_forms(
      ...>   transform_opts: [transform: fn _ -> 42 end])
      {:ok, {42, 42}}

      iex> quote(do: x = 42) |> harnais_form_test_forms(
      ...>   transform: [fn ast -> {ast, 42} end, fn {_ast,ndx} -> ndx end])
      {:ok, {42, 42}}

      iex> {:error, error} = quote(do: x = 42) |> harnais_form_test_forms(
      ...>   transform: fn _ -> %{a: 1} end)
      ...> error |> Harnais.Error.export_exception
      {:ok, [error: [[m: "form invalid, got: %{a: 1}"]]]}

      iex> quote(do: x = 42) |> harnais_form_test_forms(
      ...>   postwalk: fn _ -> 43 end)
      {:ok, {43, 43}}

      iex> quote(do: x = 42) |> harnais_form_test_forms(
      ...>   postwalk: fn snippet ->
      ...>     case snippet do
      ...>       {:x, [], module} when is_atom(module) -> quote(do: a)
      ...>       # passthru
      ...>       x -> x
      ...>     end
      ...>   end)
      {:ok, {42, quote(do: a = 42)}}

      iex> quote(do: x = 42) |> harnais_form_test_forms(
      ...>   replace_vars: [x: quote(do: a)])
      {:ok, {42, quote(do: a = 42)}}

      iex> quote(do: x = var!(a)) |> harnais_form_test_forms(
      ...>   eval_binding: [b: 99],
      ...>   replace_vars: [a: quote(do: b)])
      {:ok, {99, quote(do: x = var!(b))}}

      iex> quote(do: x = a) |> harnais_form_test_forms(
      ...>   eval_binding: [b: 99],
      ...>   replace_vars: [a: Macro.var(:b, nil)])
      {:ok, {99, quote(do: x = unquote(Macro.var(:b, nil)))}}

      iex> {:error, error} = harnais_form_test_forms(%{a: 1})
      ...> error |> Harnais.Error.export_exception
      {:ok, [error: [[m: "form invalid, got: %{a: 1}"]]]}

  Bang examples:

      iex> harnais_form_test_forms!(42)
      {42, 42}

      iex> quote(do: x = 42) |> harnais_form_test_forms!(
      ...>   transform: fn _ -> %{a: 1} end)
      ** (ArgumentError) form invalid, got: %{a: 1}

      iex> quote(do: x = 42) |> harnais_form_test_forms!(
      ...>   postwalk: fn _ -> 42 end)
      {42, 42}

      iex> quote(do: x = a) |> harnais_form_test_forms!(
      ...>   eval_binding: [b: 99],
      ...>   replace_vars: [a: Macro.var(:b, nil)])
      {99, quote(do: x = unquote(Macro.var(:b, nil)))}

      iex> harnais_form_test_forms!(%{a: 1})
      ** (ArgumentError) form invalid, got: %{a: 1}

  """

  @spec harnais_form_test_forms(forms, opts) :: {:ok, any} | {:error, error}

  def harnais_form_test_forms(forms, opts \\ [])

  def harnais_form_test_forms(nil, _opts) do
    {:ok, nil}
  end

  def harnais_form_test_forms(forms, opts) do
    with {:ok, opts} <- opts |> opts_normalise,
         {:ok, {values, %HAS{}}} <-
           forms |> HAS.produce_schatten(@harnais_form_test_forms_default_opts ++ opts) do
      {:ok, values |> Keyword.values() |> List.to_tuple()}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""
  `harnais_form_transform_forms/2` takes a *forms* together with optional
  *opts* and transforms the *forms* returning `{:ok, forms}` or `{:error, error}`

  Note the transformed *forms* do *not* have to be quoted forms.

  ## Transformations

  The function is a convenience wrapper for `Plymio.Fontais.Form.forms_edit/2` and the transforms include :

  1. `:postwalk`
  1. `:prewalk`
  1. `:transform`
  1. `:replace_vars`
  1. `:rename_vars`
  1. `:rename_atoms`
  1. `:rename_funs`

  ## Examples

      iex> harnais_form_transform_forms(42)
      {:ok, [42]}

      iex> quote(do: x = 42) |> harnais_form_transform_forms
      {:ok, [quote(do: x = 42)]}

      iex> quote(do: x = 42) |> harnais_form_transform_forms(
      ...>   transform: fn _ -> 42 end)
      {:ok, [42]}

      iex> quote(do: x = 42) |> harnais_form_transform_forms(
      ...>   transform: [fn form -> {form, 42} end, fn {_form,ndx} -> ndx end])
      {:ok, [42]}

      iex> quote(do: x = 42) |> harnais_form_transform_forms(
      ...>   transform: fn _ -> %{a: 1} end)
      {:ok, [%{a: 1}]}

      iex> quote(do: x = 42) |> harnais_form_transform_forms(
      ...>   postwalk: fn _ -> 42 end)
      {:ok, [42]}

  The next two examples show the `x` var being renamed.  The first
  uses an explicit `:postwalk` while the second uses `:rename_vars`.

      iex> quote(do: x = 42) |> harnais_form_transform_forms(
      ...>   postwalk: fn snippet ->
      ...>     case snippet do
      ...>       {:x, [], module} when is_atom(module) -> quote(do: a)
      ...>       # passthru
      ...>       x -> x
      ...>     end
      ...>   end)
      {:ok, [quote(do: a = 42)]}

      iex> quote(do: x = 42) |> harnais_form_transform_forms(
      ...>   replace_vars: [x: quote(do: a)])
      {:ok, [quote(do: a = 42)]}

  The *opts*, if any, are validated:

      iex> {:error, error} = quote(do: x = 42) |> harnais_form_transform_forms(:opts_not_keyword)
      ...> error |> Exception.message
      "transform failed, got: opts invalid, got: :opts_not_keyword"

  The *forms* are validated:

      iex> {:error, error} = %{a: 1} |> harnais_form_transform_forms
      ...> error |> Exception.message
      "forms invalid, got invalid indices: [0]"

  Bang examples:

      iex> harnais_form_transform_forms!(42)
      [42]

      iex> quote(do: x = 42) |> harnais_form_transform_forms!(
      ...>   transform: [fn ast -> {ast, 42} end, fn {_ast,ndx} -> ndx end])
      [42]

      iex> harnais_form_transform_forms!(quote(do: x = 42),
      ...>   replace_vars: [x: quote(do: a)])
      [quote(do: a = 42)]

      iex> quote(do: x = 42) |> harnais_form_transform_forms!(
      ...>   replace_vars: [x: quote(do: a)])
      {:ok, quote(do: a = 42)}
      [quote(do: a = 42)]

      iex> {:error, error} = harnais_form_transform_forms(%{a: 1})
      ...> error |> Exception.message
      "forms invalid, got invalid indices: [0]"

      iex> {:error, error} = harnais_form_transform_forms(quote(do: x = 42), :opts_not_keyword)
      ...> error |> Exception.message
      "transform failed, got: opts invalid, got: :opts_not_keyword"
  """

  @spec harnais_form_transform_forms(forms, opts) :: {:ok, any} | {:error, error}

  def harnais_form_transform_forms(forms, opts \\ [])

  def harnais_form_transform_forms(forms, []) do
    forms |> harnais_forms
  end

  def harnais_form_transform_forms(forms, opts) do
    with {:ok, opts} <- opts |> opts_validate,
         {:ok, forms} <- forms |> harnais_forms,
         {:ok, _forms} = result <- forms |> forms_edit(opts) do
      result
    else
      {:error, %{__exception__: true} = error} ->
        HEE.new_error_result(m: "transform failed", v: error)
    end
  end

  @doc_harnais_form_format_form ~S"""
  `harnais_form_format_form/2` takes either a *form* or string as its argument, together with optional *opts*.

  A form is converted first to text using `Macro.to_string/1`, reduced
  (`Plymio.Fontais.Form.forms_reduce/1`) and then the text is passed
  through the Elixir code formatter (`Code.format_string!/2`),
  together with the *opts*.

  It returns `{:ok, text}` if normalisation succeeds, else `{:error, error}`

  ## Examples

      iex> harnais_form_format_form(42)
      {:ok, "42"}

      iex> harnais_form_format_form(:atom)
      {:ok, ":atom"}

      iex> harnais_form_format_form("string")
      {:ok, "string"}

  Quoted form:

      iex> quote(do: Map.get(  %{a: 1},   :a, 42)) |> harnais_form_format_form
      {:ok, "Map.get(%{a: 1}, :a, 42)"}

  Already text but "untidy":

      iex> "Map.get(  %{a: 1},   :a, 42)   " |> harnais_form_format_form
      {:ok, "Map.get(%{a: 1}, :a, 42)"}
  """

  @doc_harnais_form_format_forms ~S"""
  `harnais_form_format_forms/2` takes a *forms*, and optional *opts*,
  and formats each *form* using `harnais_form_format_form/2` returning
  `{:ok, texts}`.

  ## Examples

      iex> [quote(do: x   = x + 1),
      ...>  quote(do: x = x   * x ),
      ...>  quote(do: x=x-1   )
      ...> ] |> harnais_form_format_forms
      {:ok, ["x = x + 1", "x = x * x", "x = x - 1"]}

      iex> [quote(do: x = x + 1),
      ...>  quote(do: x = x * x),
      ...>  quote(do: x = x - 1)
      ...> ] |> harnais_form_format_forms!
      ["x = x + 1", "x = x * x", "x = x - 1"]
  """

  @doc ~S"""
  `harnais_form_compare_texts/3` takes two arguments, either forms or strings, together with (optional) *opts*.

  Each argument is normalised to text using `harnais_form_format_form/2` and then compared (`Kernel.==/2`).

  It returns `{:ok, text}` if the compare succeeds, else `{:error, error}`

  ## Examples

      iex> harnais_form_compare_texts(42, 42)
      {:ok, "42"}

      iex> harnais_form_compare_texts(
      ...>   quote(do: Map.get(  %{a: 1},   :a, 42)),
      ...>   "Map.get(%{a: 1}, :a, 42)")
      {:ok, "Map.get(%{a: 1}, :a, 42)"}

      iex> harnais_form_compare_texts(
      ...>   quote(do: Map.get(%{a: 1}, :a, 42)),
      ...>   "Map.get(  %{a: 1},   :a, 42)")
      {:ok, "Map.get(%{a: 1}, :a, 42)"}

      iex> {:error, error} = harnais_form_compare_texts(quote(do: x = 42), "x = 41")
      ...> error |> Exception.message
      "form compare failed, reason=:mismatch, type=:arg, value1=x = 42, value2=x = 41"

      iex> {:error, error} = harnais_form_compare_texts("x = 42", quote(do: x = 41))
      ...> error |> Harnais.Error.export_exception
      {:ok, [error: [[m: "form compare failed", r: :mismatch, t: :arg, v1: "x = 42", v2: "x = 41"]]]}

  Query examples:

      iex> harnais_form_compare_texts?(42, 42)
      true

      iex> harnais_form_compare_texts?(
      ...>   quote(do: (def f(x,y), do: x + y)),
      ...>   "def(f(x, y)) do\n x + y\n end")
      true

      iex> harnais_form_compare_texts?(quote(do: x = 42), "x = 41")
      false

      iex> harnais_form_compare_texts?("x = 42", quote(do: x = 41))
      false

  Bang examples:

      iex> harnais_form_compare_texts!(42, 42)
      "42"

      iex> harnais_form_compare_texts!(
      ...>   quote(do: Map.get(%{a: 1}, :a, 42)),
      ...>   "Map.get(  %{a: 1},   :a, 42)")
      "Map.get(%{a: 1}, :a, 42)"

      iex> harnais_form_compare_texts!(
      ...>   quote(do: (def f(x,y), do: x + y)),
      ...>   "def(f(x, y)) do\n x + y\n end")
      "def(f(x, y)) do\n  x + y\nend"

      iex> harnais_form_compare_texts!(quote(do: x = 42), "x = 41")
      ** (Harnais.Error) form compare failed, reason=:mismatch, type=:arg, value1=x = 42, value2=x = 41
  """

  @spec harnais_form_compare_texts(any, any, opts) :: {:ok, binary} | {:error, error}

  def harnais_form_compare_texts(actual_code, expect_code, opts \\ [])

  def harnais_form_compare_texts(actual_code, expect_code, opts) do
    with {:ok, actual_text} <- actual_code |> harnais_form_format_form(opts),
         {:ok, expect_text} <- expect_code |> harnais_form_format_form(opts) do
      case actual_text == expect_text do
        true ->
          {:ok, actual_text}

        _ ->
          HEE.new_error_result(
            m: @harnais_form_message_text_form_compare_failed,
            t: @harnais_error_value_field_type_arg,
            r: @harnais_error_reason_mismatch,
            v1: actual_text,
            v2: expect_text
          )
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @doc ~S"""

  `harnais_form_compare_forms/3` takes two arguments and optional *opts*.

  If either argument is text (i.e binary), it performs a textual
  comparison using `harnais_form_compare_texts/3` and returns `{:ok, first_argument}`
  if the compare succeeds, else returns the `{:error, error}`.

  If both arguments are forms, it runs `Macro.postwalk/3` on both,
  collecting each form's `snippets` in the accumulator, and then calls
  `Harnais.List.harnais_list_compare/2` to compare the two
  accumulators returning `{:ok, first_argument}` else `{:error, error}`
  from the list compare.

  ## Examples

  Mixed form and text:

      iex> harnais_form_compare_forms(42, "42")
      {:ok, 42}

      iex> harnais_form_compare_forms(
      ...>   quote(do: Map.get(  %{a: 1},   :a, 42)),
      ...>   "Map.get(%{a: 1}, :a, 42)")
      {:ok, quote(do: Map.get(%{a: 1}, :a, 42))}

      iex> harnais_form_compare_forms(
      ...>   quote(do: (def f(x,y), do: x + y)),
      ...>   "def(f(x, y)) do\n x + y\n end")
      {:ok, quote(do: (def f(x,y), do: x + y))}

  Both forms:

      iex> harnais_form_compare_forms(42, 42)
      {:ok, 42}

      iex> harnais_form_compare_forms(
      ...>   quote(do: Map.get(  %{a: 1},   :a, 42)),
      ...>   quote(do: Map.get(%{a: 1}, :a, 42)))
      {:ok, quote(do: Map.get(%{a: 1}, :a, 42))}

      iex> {:error, error} = harnais_form_compare_forms(
      ...>   quote(do: Map.get(  %{a: 1},   :a, 42)),
      ...>   quote(do: Map.get(%{a: 1}, :a, 41)))
      ...> error |> Exception.message
      "form compare failed, reason=:mismatch, type=:value, location=9, value1=42, value2=41"

  Note vars with same name (`:x`) but in different modules (`ModA` v `ModB`) will be cuaght:

      iex> {:error, error} = harnais_form_compare_forms(
      ...>   Macro.var(:x, ModA),
      ...>   Macro.var(:x, ModB))
      ...> error |> Exception.message
      "form compare failed, reason=:mismatch, type=:value, location=0, value1={:x, [], ModA}, value2={:x, [], ModB}"

  Query examples:

      iex> harnais_form_compare_forms?(
      ...>   quote(do: Map.get(  %{a: 1},   :a, 42)),
      ...>   "Map.get(%{a: 1}, :a, 42)")
      true

      iex> harnais_form_compare_forms?(quote(do: x = 42), "x = 41")
      false

      iex> harnais_form_compare_forms?(
      ...>   Macro.var(:x, ModA),
      ...>   Macro.var(:x, ModB))
      false

  Bang examples:

      iex> harnais_form_compare_forms!(42, "42")
      42

      iex> harnais_form_compare_forms!(quote(do: x = 42), "x = 41")
      ** (Harnais.Error) form compare failed, reason=:mismatch, type=:arg, value1=x = 42, value2=x = 41

      iex> harnais_form_compare_forms!(
      ...>   Macro.var(:x, ModA),
      ...>   Macro.var(:x, ModB))
      ** (Harnais.Error) form compare failed, reason=:mismatch, type=:value, location=0, value1={:x, [], ModA}, value2={:x, [], ModB}
  """

  @spec harnais_form_compare_forms(ast, any, opts) ::
          {:ok, form} | {:ok, binary} | {:error, error}

  def harnais_form_compare_forms(actual_code, expect_code, opts \\ [])

  def harnais_form_compare_forms(actual_code, expect_code, opts)
      when is_binary(actual_code) or is_binary(expect_code) do
    # do a text compare
    harnais_form_compare_texts(actual_code, expect_code, opts)
    |> case do
      {:ok, _} -> {:ok, actual_code}
      x -> x
    end
  end

  def harnais_form_compare_forms(actual_code, expect_code, opts) do
    with {:ok, actual_form} <- actual_code |> harnais_form,
         {:ok, expect_form} <- expect_code |> harnais_form do
      actual_snippets =
        actual_form
        |> Macro.postwalk([], fn snippet, snippets -> {nil, [snippet | snippets]} end)
        |> elem(1)
        |> Enum.reverse()

      expect_snippets =
        expect_form
        |> Macro.postwalk([], fn snippet, snippets -> {nil, [snippet | snippets]} end)
        |> elem(1)
        |> Enum.reverse()

      case HUL.harnais_list_compare(actual_snippets, expect_snippets, opts) do
        {:ok, _} ->
          {:ok, actual_code}

        {:error, %Harnais.Error{} = error} ->
          {:error,
           error
           |> struct!([
             {@harnais_error_field_message, @harnais_form_message_text_form_compare_failed}
           ])}

        x ->
          x
      end
    end
  end

  @doc_harnais_form ~S"""
  `harnais_form/1` tests whether the argument is a quoted form and,
   if true, returns `{:ok, form}` else returns `{:error, error}`.

  (Delegated to `Harnais.Utility.form_validate/1`)

  ## Examples

      iex> harnais_form(42)
      {:ok, 42}

      iex> harnais_form(:atom)
      {:ok, :atom}

      iex> {:error, error} = harnais_form(%{a: 1})
      ...> error |> Exception.message
      "form invalid, got: %{a: 1}"

      ies> Macro.escape(%{a: 1}) |> harnais_form
      {:ok, Macro.escape(%{a: 1})}

  Query examples:

      iex> harnais_form?(42)
      true

      iex> harnais_form?(quote(do: x = 42))
      true

      iex> harnais_form?(%{a: 1})
      false

  Bang examples:

      iex> harnais_form!(42)
      42

      iex> harnais_form!(quote(do: x = 42))
      quote(do: x = 42)

      iex> harnais_form!(%{a: 1})
      ** (ArgumentError) form invalid, got: %{a: 1}

  """

  @doc_harnais_forms ~S"""
  `harnais_forms/1` validates the *forms* returning `{:ok, forms}` if
  all are valid, else `{:error, error}`.

  (Delegated to `Harnais.Utility.forms_normalise/1`)

  ## Examples

      iex> [1, 2, 3] |> harnais_forms
      {:ok, [1, 2, 3]}

      iex> 1 |> harnais_forms
      {:ok, [1]}

      iex> [1, {2, 2}, :three] |> harnais_forms
      {:ok, [1, {2, 2}, :three]}

  Query examples:

      iex> [1, 2, 3] |> harnais_forms?
      true

      iex> [1, {2, 2}, :three] |> harnais_forms?
      true

      iex> [1, {2, 2, 2}, %{c: 3}] |> harnais_forms?
      false

  Bang examples:

      iex> [1, 2, 3] |> harnais_forms!
      [1, 2, 3]

      iex> [1, {2, 2}, :three] |> harnais_forms!
      [1, {2, 2}, :three]

      iex> [1, {2, 2, 2}, %{c: 3}] |> harnais_forms!
      ** (ArgumentError) forms invalid, got invalid indices: [1, 2]
  """

  @quote_result_list_no_return quote(do: list | no_return)
  @quote_result_text_no_return quote(do: String.t() | no_return)
  @quote_result_texts_no_return quote(do: [String.t()] | no_return)
  @quote_result_form_no_return quote(do: form | no_return)
  @quote_result_forms_no_return quote(do: forms | no_return)
  @quote_result_form_result quote(do: {:ok, form} | {:error, error})
  @quote_result_forms_no_return quote(do: forms | no_return)
  @quote_result_forms_texts_result quote(do: {:ok, [String.t()]} | {:error, error})

  [
    delegate: [
      name: :harnais_form,
      as: :form_validate,
      to: Harnais.Utility,
      doc: @doc_harnais_form,
      args: :form,
      spec_args: :any,
      since: "0.1.0",
      result: @quote_result_form_result
    ],
    bang: [
      doc: false,
      as: :harnais_form,
      args: :form,
      since: "0.1.0",
      result: @quote_result_form_no_return
    ],
    query: [doc: false, as: :harnais_form, args: :form, since: "0.1.0", result: true],
    delegate: [
      name: :harnais_forms,
      as: :forms_normalise,
      to: Harnais.Utility,
      doc: @doc_harnais_forms,
      args: :forms,
      spec_args: :any,
      since: "0.1.0",
      result: @quote_result_form_result
    ],
    bang: [
      doc: false,
      as: :harnais_forms,
      args: :forms,
      since: "0.1.0",
      result: @quote_result_forms_no_return
    ],
    query: [doc: false, as: :harnais_forms, args: :forms, since: "0.1.0", result: true],
    bang: [
      doc: false,
      as: :harnais_form_transform_forms,
      args: :form,
      since: "0.1.0",
      result: @quote_result_list_no_return
    ],
    bang: [
      doc: false,
      as: :harnais_form_transform_forms,
      args: [:form, :opts],
      since: "0.1.0",
      result: @quote_result_list_no_return
    ],
    bang: [
      doc: false,
      as: :harnais_form_compare_forms,
      args: [:form1, :form2],
      since: "0.1.0",
      result: @quote_result_forms_no_return
    ],
    bang: [
      doc: false,
      as: :harnais_form_compare_forms,
      args: [:form1, :form2, :opts],
      since: "0.1.0",
      result: @quote_result_forms_no_return
    ],
    query: [
      doc: false,
      as: :harnais_form_compare_forms,
      args: [:form1, :form2],
      since: "0.1.0",
      result: true
    ],
    query: [
      doc: false,
      as: :harnais_form_compare_forms,
      args: [:form1, :form2, :opts],
      since: "0.1.0",
      result: true
    ],
    bang: [
      doc: false,
      as: :harnais_form_compare_texts,
      args: [:code1, :code2],
      since: "0.1.0",
      result: @quote_result_text_no_return
    ],
    bang: [
      doc: false,
      as: :harnais_form_compare_texts,
      args: [:code1, :code2, :opts],
      since: "0.1.0",
      result: @quote_result_text_no_return
    ],
    query: [
      doc: false,
      as: :harnais_form_compare_texts,
      args: [:code1, :code2],
      since: "0.1.0",
      result: true
    ],
    query: [
      doc: false,
      as: :harnais_form_compare_texts,
      args: [:code1, :code2, :opts],
      since: "0.1.0",
      result: true
    ],
    bang: [
      doc: false,
      as: :harnais_form_test_forms,
      args: :forms,
      since: "0.1.0",
      result: @quote_result_forms_no_return
    ],
    bang: [
      doc: false,
      as: :harnais_form_test_forms,
      args: [:forms, :opts],
      since: "0.1.0",
      result: @quote_result_forms_no_return
    ],
    delegate: [
      name: :harnais_form_format_form,
      as: :form_format,
      to: Harnais.Form.Utility,
      doc: false,
      args: :form,
      spec_args: :any,
      spec_result: @quote_result_forms_texts_result
    ],
    delegate: [
      name: :harnais_form_format_form,
      as: :form_format,
      to: Harnais.Form.Utility,
      doc: @doc_harnais_form_format_form,
      args: [:form, :opts],
      spec_args: [:any, :any],
      spec_result: @quote_result_forms_texts_result
    ],
    bang: [
      doc: false,
      as: :harnais_form_format_form,
      args: :form,
      since: "0.1.0",
      result: @quote_result_text_no_return
    ],
    bang: [
      doc: false,
      as: :harnais_form_format_form,
      args: [:form, :opts],
      since: "0.1.0",
      result: @quote_result_text_no_return
    ],
    delegate: [
      name: :harnais_form_format_forms,
      as: :forms_format,
      to: Harnais.Form.Utility,
      doc: false,
      args: :forms,
      spec_args: :any,
      spec_result: @quote_result_forms_texts_result
    ],
    delegate: [
      name: :harnais_form_format_forms,
      as: :forms_format,
      to: Harnais.Form.Utility,
      doc: @doc_harnais_form_format_forms,
      args: [:forms, :opts],
      spec_args: [:any, :any],
      spec_result: @quote_result_forms_texts_result
    ],
    bang: [
      doc: false,
      as: :harnais_form_format_forms,
      args: :forms,
      since: "0.1.0",
      result: @quote_result_texts_no_return
    ],
    bang: [
      doc: false,
      as: :harnais_form_format_forms,
      args: [:forms, :opts],
      since: "0.1.0",
      result: @quote_result_texts_no_return
    ]
  ]
  |> Enum.flat_map(fn {pattern, opts} ->
    [pattern: [pattern: pattern] ++ opts]
  end)
  |> CODI.reify_codi(@codi_opts)
end
