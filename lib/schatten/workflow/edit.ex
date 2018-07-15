defmodule Harnais.Form.Schatten.Workflow.Edit do
  @moduledoc false

  require Plymio.Fontais.Option
  alias Harnais.Form.Schatten, as: HAS

  use Harnais.Form.Attribute.Schatten

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Guard,
    only: [
      is_value_unset: 1
    ]

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Option,
    only: [
      opts_validate: 1
    ]

  import Harnais.Form.Schatten.Workflow.Utility,
    only: [
      validate_workflow_pipeline: 1,
      normalise_workflow_pipeline: 1,
      collate_workflow_pipeline: 1
    ]

  def state_edit_workflow_pipeline_add_tail(state, tuple) do
    state
    |> state_edit_workflow_pipeline([
      {@harnais_form_schatten_workflow_pipeline_edit_verb_add_tail, tuple}
    ])
  end

  def edit_workflow_pipeline(pipeline, edits \\ [])

  def edit_workflow_pipeline(pipeline, edits)
      when is_value_unset(pipeline) do
    [] |> edit_workflow_pipeline(edits)
  end

  def edit_workflow_pipeline(pipeline, []) do
    pipeline |> validate_workflow_pipeline
  end

  def edit_workflow_pipeline(pipeline, edits) do
    with {:ok, edits} <- edits |> opts_validate,
         {:ok, pipeline} <- pipeline |> validate_workflow_pipeline do
      edits
      |> Enum.reduce_while(
        pipeline,
        fn {verb, args}, pipeline ->
          verb
          |> case do
            @harnais_form_schatten_workflow_pipeline_edit_verb_add_tail ->
              with {:ok, pipeline_new} <- args |> normalise_workflow_pipeline do
                {:cont, pipeline ++ pipeline_new}
              else
                {:error, %{__struct__: _}} = result -> {:halt, result}
              end

            @harnais_form_schatten_workflow_pipeline_edit_verb_add_head ->
              with {:ok, pipeline_new} <- args |> normalise_workflow_pipeline do
                {:cont, pipeline_new ++ pipeline}
              else
                {:error, %{__struct__: _}} = result -> {:halt, result}
              end

            @harnais_form_schatten_workflow_pipeline_edit_verb_collate ->
              with {:ok, pipeline} <- pipeline |> collate_workflow_pipeline do
                {:cont, pipeline}
              else
                {:error, %{__struct__: _}} = result -> {:halt, result}
              end

            @harnais_form_schatten_workflow_pipeline_edit_verb_filter ->
              case args |> is_function(1) do
                true ->
                  {:cont, pipeline |> Enum.filter(args)}

                _ ->
                  new_error_result(m: "workflow pipeline filter function invalid", v: args)
              end

            @harnais_form_schatten_workflow_pipeline_edit_verb_reject ->
              case args |> is_function(1) do
                true ->
                  {:cont, pipeline |> Enum.reject(args)}

                _ ->
                  new_error_result(m: "workflow pipeline reject function invalid", v: args)
              end
          end
        end
      )
      |> case do
        {:error, %{__exception__: true}} = result ->
          result

        pipeline ->
          with {:ok, pipeline} <- pipeline |> validate_workflow_pipeline do
            {:ok, pipeline}
          else
            {:error, %{__exception__: true}} = result -> result
          end
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def state_edit_workflow_pipeline(state, edits \\ [])

  def state_edit_workflow_pipeline(state, []) do
    {:ok, state}
  end

  def state_edit_workflow_pipeline(
        %HAS{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state,
        edits
      ) do
    with {:ok, pipeline} <- pipeline |> edit_workflow_pipeline(edits),
         {:ok, %HAS{}} = result <- state |> HAS.schatten_update_workflow_pipeline(pipeline) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
