defmodule Harnais.Form.Schatten.Workflow.Run do
  @moduledoc false

  alias Harnais.Form.Schatten, as: HAS
  alias Harnais.Form.Utility, as: HAU
  alias Harnais.Form.Schatten.Workflow.Transform, as: HASWT
  alias Harnais.Form.Schatten.Workflow.Filter, as: HASWF
  alias Harnais.Form.Schatten.Workflow.Edit, as: HASWE

  use Harnais.Error.Attribute
  use Harnais.Form.Attribute
  use Harnais.Form.Attribute.Schatten

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Guard,
    only: [
      is_value_unset: 1,
      is_filled_list: 1
    ]

  import Plymio.Fontais.Option,
    only: [
      opts_merge: 1
    ]

  import Plymio.Fontais.Form,
    only: [
      form_validate: 1,
      forms_reduce: 1
    ]

  import Plymio.Fontais.Result,
    only: [
      normalise1_result: 1
    ]

  import Plymio.Funcio.Enum.Map.Collate,
    only: [
      map_collate0_enum: 2,
      map_collate2_enum: 2
    ]

  import Harnais.Form.Utility,
    only: [
      forms_validate: 1,
      forms_normalise: 1
    ]

  def run_workflow_pipeline_tuple(state, kv)

  def run_workflow_pipeline_tuple(
        %HAS{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state,
        {verb, field, value}
      )
      when is_filled_list(pipeline) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_error do
    # check if there is there an actual error
    with {:ok, actual_error_tuples} <-
           pipeline
           |> HASWF.filter_workflow_pipeline_by_verb_field(
             @harnais_form_schatten_workflow_verb_actual,
             field
           ) do
      actual_error_tuples
      |> case do
        [] ->
          {:ok, state}

        _ ->
          state
          |> HASWT.workflow_transform_pattern_pipeline(
            {verb, field, value},
            {@harnais_form_schatten_workflow_verb_actual, field, :ignore}
          )
      end
    else
      {:error, %{__struct__: _}} = result -> result
    end
  end

  # bootstraps both form and forms
  def run_workflow_pipeline_tuple(
        %HAS{@harnais_form_schatten_field_form => asts} = state,
        {verb, field, value}
      )
      when verb == @harnais_form_schatten_workflow_verb_build and is_value_unset(value) and
             field == @harnais_form_schatten_field_bootstrap_form do
    asts
    |> List.wrap()
    |> map_collate0_enum(fn value ->
      value
      |> case do
        fun when is_function(fun, 1) ->
          fun.(state)
          |> normalise1_result
          |> case do
            {:error, %{__struct__: _} = error} ->
              new_error_result(
                m: @harnais_form_schatten_error_text_forms_generator_failed,
                v: error
              )

            {:ok, value} ->
              cond do
                Keyword.keyword?(value) ->
                  {:ok, value}

                # treat anything else as forms
                true ->
                  with {:ok, forms} <- value |> forms_normalise do
                    {:ok, [{@harnais_form_schatten_key_forms, forms}]}
                  else
                    {:error, %{__struct__: _} = error} ->
                      new_error_result(
                        m: @harnais_form_schatten_error_text_forms_generator_failed,
                        v: error
                      )
                  end
              end
          end

        value ->
          with {:ok, forms} <- value |> forms_normalise do
            {:ok, [{@harnais_form_schatten_key_forms, forms}]}
          else
            {:error, %{__struct__: _}} = result -> result
          end
      end
    end)
    |> case do
      {:error, %{__exception__: true}} = result ->
        result

      {:ok, opzioni} ->
        with {:ok, opts} <- opzioni |> opts_merge do
          opts
          |> map_collate2_enum(fn
            {@harnais_form_schatten_key_form, form} ->
              {:ok, [form]}

            {@harnais_form_schatten_key_forms, forms} ->
              {:ok, forms}

            # drop anything else
            _ ->
              nil
          end)
          |> case do
            {:ok, forms} ->
              # need the initial value of [] just in case forms is empty
              with forms <- forms |> Enum.reduce([], fn v, s -> s ++ v end),
                   {:ok, forms} <- forms |> forms_validate,
                   {:ok, form} <- forms |> forms_reduce,
                   # add the form and forms to the workflow pipeline
                   {:ok, %HAS{}} = result <-
                     state
                     |> HASWE.state_edit_workflow_pipeline_add_tail([
                       {@harnais_form_schatten_workflow_verb_actual,
                        @harnais_form_schatten_field_form, form},
                       {@harnais_form_schatten_workflow_verb_actual,
                        @harnais_form_schatten_field_forms, forms}
                     ]) do
                result
              else
                {:error, %{__exception__: true}} = result -> result
              end
          end
        else
          {:error, %{__exception__: true}} = result -> result
        end
    end
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_transform_form do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      [{verb, field, value}, {verb, field, fn {_, _, forms} -> forms |> form_validate end}],
      {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_form, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_transform_forms do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      [{verb, field, value}, {verb, field, fn {_, _, forms} -> forms |> form_validate end}],
      {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_forms, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(
        %HAS{
          @harnais_form_schatten_field_workflow_pipeline => pipeline,
          @harnais_form_schatten_field_eval_binding => eval_binding,
          @harnais_form_schatten_field_eval_opts => eval_opts
        } = state,
        {verb, field, value}
      )
      when verb == @harnais_form_schatten_workflow_verb_build and is_value_unset(value) and
             field == @harnais_form_schatten_field_result do
    with {:ok, {_, _, eval_form}} <-
           pipeline
           |> HASWF.filter_workflow_pipeline_by_last_verb_field(
             @harnais_form_schatten_workflow_verb_actual,
             @harnais_form_schatten_field_form
           ) do
      cond do
        # no binding => result is nil
        eval_binding == @harnais_form_schatten_value_eval_binding_initial ->
          state
          |> HASWE.state_edit_workflow_pipeline_add_tail(
            {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_result,
             nil}
          )

        true ->
          eval_opts =
            cond do
              eval_opts == @harnais_form_schatten_value_eval_opts_initial -> []
              true -> eval_opts
            end

          with {:ok, {result, _form}} <-
                 eval_form |> HAU.form_eval(eval_binding: eval_binding, eval_opts: eval_opts) do
            state
            |> HASWE.state_edit_workflow_pipeline_add_tail(
              {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_result,
               result}
            )
          else
            {:error, %{__exception__: true}} = result -> result
          end
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_form do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      [{verb, field, value}, {verb, field, fn {_, _, form} -> form |> form_validate end}],
      {@harnais_form_schatten_workflow_verb_actual, field, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_forms do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      [{verb, field, value}, {verb, field, fn {_, _, forms} -> forms |> forms_validate end}],
      {@harnais_form_schatten_workflow_verb_actual, field, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_text do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      {verb, field, value},
      {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_form, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_texts do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      {verb, field, value},
      {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_forms, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_format_text do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      {verb, field, value},
      {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_text, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_format_texts do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      {verb, field, value},
      {@harnais_form_schatten_workflow_verb_actual, @harnais_form_schatten_field_texts, :ignore}
    )
  end

  # default where the transform pipeline uses the field's actual tuple
  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_build do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      {verb, field, value},
      {@harnais_form_schatten_workflow_verb_actual, field, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, _field, _value})
      when verb == @harnais_form_schatten_workflow_verb_actual do
    {:ok, state}
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_express do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      [
        {verb, field, value},
        {verb, field,
         fn {_actual_verb, actual_field, actual_value} ->
           {:ok, {@harnais_form_schatten_workflow_verb_produce, actual_field, actual_value}}
         end}
      ],
      {@harnais_form_schatten_workflow_verb_actual, field, :ignore}
    )
  end

  def run_workflow_pipeline_tuple(%HAS{} = state, {verb, field, value})
      when verb == @harnais_form_schatten_workflow_verb_expect do
    state
    |> HASWT.workflow_transform_pattern_pipeline(
      [
        {verb, field, value}
      ],
      {@harnais_form_schatten_workflow_verb_actual, field, :ignore}
    )
  end
end
