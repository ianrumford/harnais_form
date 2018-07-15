defmodule Harnais.Form.Schatten.Workflow.Transform do
  @moduledoc false

  require Plymio.Fontais.Option
  alias Harnais.Form.Schatten, as: HAS
  alias Harnais.Form.Schatten.Workflow.Utility, as: HASWU
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

  import Plymio.Fontais.Result,
    only: [
      normalise0_result: 1
    ]

  import Plymio.Funcio.Enum.Reduce,
    only: [
      reduce0_enum: 3
      # reduce2_enum: 3,
    ]

  @type t :: %HAS{}
  @type form :: Harnais.ast()
  @type forms :: Harnais.asts()
  @type kv :: {any, any}
  @type opts :: Harnais.opts()
  @type error :: Harnais.error()

  def workflow_transform_target_tuple(schatten, transform_tuple, target_tuple)

  def workflow_transform_target_tuple(
        %HAS{} = state,
        {_transform_verb, _transform_field, transform_value},
        {target_verb, target_field, _target_value} = target_tuple
      ) do
    cond do
      is_value_unset(transform_value) ->
        {:ok, {target_tuple, state}}

      is_function(transform_value, 2) ->
        transform_value.(state, target_tuple)
        |> normalise0_result
        |> case do
          {:error, %{__struct__: _}} = result ->
            result

          {:ok, {{answer_verb, answer_field, _} = tuple, %HAS{} = state}}
          when is_atom(answer_verb) and is_atom(answer_field) ->
            with {:ok, tuple} <- tuple |> HASWU.validate_workflow_pipeline_tuple() do
              {:ok, {tuple, state}}
            else
              {:error, %{__exception__: true}} = result -> result
            end

          {:ok, {answer_verb, answer_field, _} = tuple}
          when is_atom(answer_verb) and is_atom(answer_field) ->
            with {:ok, tuple} <- tuple |> HASWU.validate_workflow_pipeline_tuple() do
              {:ok, {tuple, state}}
            else
              {:error, %{__exception__: true}} = result -> result
            end

          {:ok, answer_value} ->
            {:ok, {{target_verb, target_field, answer_value}, state}}
        end

      is_function(transform_value, 1) ->
        transform_value.(target_tuple)
        |> normalise0_result
        |> case do
          {:error, %{__struct__: _}} = result ->
            result

          {:ok, {answer_verb, answer_field, _} = tuple}
          when is_atom(answer_verb) and is_atom(answer_field) ->
            with {:ok, tuple} <- tuple |> HASWU.validate_workflow_pipeline_tuple() do
              {:ok, {tuple, state}}
            else
              {:error, %{__exception__: true}} = result -> result
            end

          {:ok, answer_value} ->
            {:ok, {{target_verb, target_field, answer_value}, state}}
        end

      true ->
        {:ok, {{target_verb, target_field, transform_value}, state}}
    end
  end

  def workflow_transform_pattern_pipeline(schatten, transform_tuple, pattern_tuple)

  def workflow_transform_pattern_pipeline(
        %HAS{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state,
        transform_pipeline,
        {pattern_verb, pattern_field, _pattern_value}
      )
      when is_filled_list(pipeline) do
    with {:ok, actual_tuple} <-
           pipeline
           |> HASWF.filter_workflow_pipeline_by_last_verb_field(pattern_verb, pattern_field),
         {:ok, transform_pipeline} <-
           transform_pipeline
           |> List.wrap()
           |> HASWU.validate_workflow_pipeline() do
      transform_pipeline
      |> reduce0_enum(
        {actual_tuple, state},
        fn transform_tuple, {actual_tuple, state} ->
          with {:ok, {{_, _, _} = answer_tuple, %HAS{} = state}} <-
                 state
                 |> workflow_transform_target_tuple(transform_tuple, actual_tuple) do
            {:ok, {answer_tuple, state}}
          else
            {:error, %{__exception__: true}} = result -> result
          end
        end
      )
      |> case do
        {:error, %{__struct__: _}} = result ->
          result

        {:ok, {answer_tuple, state}} ->
          state |> HASWE.state_edit_workflow_pipeline_add_tail(answer_tuple)
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def workflow_transform_pattern_pipeline(%HAS{} = state, _transform_tuple, _pattern_tuple) do
    {:ok, state}
  end
end
