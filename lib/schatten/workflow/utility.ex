defmodule Harnais.Form.Schatten.Workflow.Utility do
  @moduledoc false

  require Plymio.Fontais.Option
  alias Harnais.Form.Schatten.Workflow.Normalise, as: HASWN

  use Harnais.Form.Attribute.Schatten

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Option,
    only: [
      opts_create_aliases_dict: 1
    ]

  import Plymio.Funcio.Enum.Map.Collate,
    only: [
      map_concurrent_collate0_enum: 2,
      map_collate2_enum: 2,
      map_concurrent_collate2_enum: 2
    ]

  @harnais_form_schatten_workflow_verb_kvs_aliases [
    {@harnais_form_schatten_workflow_verb_build, nil},
    {@harnais_form_schatten_workflow_verb_expect, nil},
    {@harnais_form_schatten_workflow_verb_actual, nil},
    {@harnais_form_schatten_workflow_verb_produce, nil},
    {@harnais_form_schatten_workflow_verb_express, nil}
  ]

  @harnais_form_schatten_workflow_verb_dict_aliases @harnais_form_schatten_workflow_verb_kvs_aliases
                                                    |> opts_create_aliases_dict

  @doc false
  def workflow_canonical_verb(verb, dict \\ @harnais_form_schatten_workflow_verb_dict_aliases) do
    case dict |> Map.fetch(verb) do
      {:ok, _verb} = result -> result
      :error -> new_error_result(m: "workflow verb invalid", v: verb)
    end
  end

  @harnais_form_schatten_workflow_field_kvs_aliases [
    {@harnais_form_schatten_field_transform_form, nil},
    {@harnais_form_schatten_field_result, []},
    {@harnais_form_schatten_field_error, []},
    {@harnais_form_schatten_field_form, []},
    {@harnais_form_schatten_field_forms, []},
    {@harnais_form_schatten_field_text, []},
    {@harnais_form_schatten_field_texts, []},
    {@harnais_form_schatten_field_format_text, []},
    {@harnais_form_schatten_field_format_texts, []}
  ]

  @harnais_form_schatten_workflow_field_dict_aliases @harnais_form_schatten_workflow_field_kvs_aliases
                                                     |> opts_create_aliases_dict

  @doc false
  def workflow_canonical_field(field, dict \\ @harnais_form_schatten_workflow_field_dict_aliases) do
    case dict |> Map.fetch(field) do
      {:ok, _field} = result -> result
      :error -> new_error_result(m: "workflow field invalid", v: field)
    end
  end

  @doc false
  def workflow_maybe_canonical_field(
        field,
        dict \\ @harnais_form_schatten_workflow_field_dict_aliases
      ) do
    case dict |> Map.fetch(field) do
      {:ok, _field} = result -> result
      :error -> {:ok, field}
    end
  end

  def validate_workflow_pipeline(pipeline)

  def validate_workflow_pipeline(pipeline) when is_list(pipeline) do
    pipeline
    |> map_concurrent_collate0_enum(&validate_workflow_pipeline_tuple/1)
  end

  def validate_workflow_pipeline(pipeline) do
    new_error_result(m: "workflow pipeline invalid", v: pipeline)
  end

  def normalise_workflow_pipeline(pipeline, opts \\ [])

  def normalise_workflow_pipeline([], []) do
    {:ok, []}
  end

  def normalise_workflow_pipeline(@harnais_form_schatten_value_workflow_pipeline_initial, _) do
    {:ok, []}
  end

  def normalise_workflow_pipeline(nil, _) do
    {:ok, []}
  end

  def normalise_workflow_pipeline(pipeline, opts) do
    default_verb = Keyword.get(opts, @harnais_form_schatten_key_verb)

    pipeline
    |> List.wrap()
    |> map_collate2_enum(fn
      nil ->
        # drop
        nil

      {_verb, _field, _value} = tuple ->
        {:ok, tuple}

      {field, value} ->
        {:ok, {default_verb, field, value}}

      field ->
        {:ok, {default_verb, field, @plymio_fontais_the_unset_value}}
    end)
    |> case do
      {:error, %{__exception__: true}} = result ->
        result

      {:ok, pipeline} ->
        with {:ok, pipeline} <-
               pipeline
               |> map_concurrent_collate2_enum(&HASWN.normalise_workflow_pipeline_tuple/1),
             {:ok, _pipeline} = result <- pipeline |> validate_workflow_pipeline do
          result
        else
          {:error, %{__exception__: true}} = result -> result
        end
    end
  end

  def validate_workflow_pipeline_tuple(value)

  def validate_workflow_pipeline_tuple({verb, field, value})
      when verb in @harnais_form_schatten_workflow_verbs_order and
             field in @harnais_form_schatten_fields_known do
    {:ok, {verb, field, value}}
  end

  def validate_workflow_pipeline_tuple(value) do
    new_error_result(m: "workflow pipeline entry invalid", v: value)
  end

  def collate_workflow_pipeline(value)

  def collate_workflow_pipeline(@harnais_form_schatten_value_workflow_pipeline_initial) do
    {:ok, []}
  end

  def collate_workflow_pipeline([]) do
    {:ok, []}
  end

  def collate_workflow_pipeline(pipeline) do
    with {:ok, pipeline} <- pipeline |> validate_workflow_pipeline do
      pipeline =
        pipeline
        |> Enum.group_by(fn {verb, _, _} -> verb end, &Tuple.delete_at(&1, 0))
        |> Enum.map(fn {verb, tuples} ->
          tuples =
            tuples
            |> Keyword.keys()
            |> Enum.uniq()
            |> Enum.map(fn field ->
              # use *last* value but maintain key order
              {field, tuples |> Keyword.get_values(field) |> List.last()}
            end)

          {verb, tuples}
        end)
        |> Keyword.split(@harnais_form_schatten_workflow_verbs_order)
        |> (fn {sorted, unsorted} -> sorted ++ unsorted end).()
        |> Enum.flat_map(fn {verb, tuples} ->
          tuples |> Enum.map(fn {field, value} -> {verb, field, value} end)
        end)

      {:ok, pipeline}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def validate_workflow_build_function(builder)

  def validate_workflow_build_function(builder) when is_function(builder, 2) do
    {:ok, builder}
  end

  def validate_workflow_build_function(builder) when is_function(builder, 1) do
    {:ok, builder}
  end

  def validate_workflow_build_function(builder) do
    new_error_result(m: "workflow build function invalid", v: builder)
  end
end
