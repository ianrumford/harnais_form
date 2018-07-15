defmodule Harnais.Form.Schatten.Workflow.Filter do
  @moduledoc false

  require Plymio.Fontais.Option
  alias Harnais.Utility, as: HUU
  alias Harnais.Form.Schatten.Workflow.Utility, as: HASWU

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

  def filter_workflow_pipeline(pipeline, fun_filter \\ nil)

  def filter_workflow_pipeline([], _) do
    {:ok, []}
  end

  def filter_workflow_pipeline(pipeline, nil) do
    pipeline |> HASWU.validate_workflow_pipeline()
  end

  def filter_workflow_pipeline(pipeline, fun_filter) when is_function(fun_filter, 1) do
    with {:ok, pipeline} <- pipeline |> HASWU.validate_workflow_pipeline(),
         {:ok, fun_filter} <-
           fun_filter
           |> HUU.value_validate_by_predicate(&is_function(&1, 1)) do
      pipeline =
        pipeline
        |> Enum.filter(fun_filter)

      {:ok, pipeline}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def filter_workflow_pipeline(_value, fun_filter) do
    new_error_result(m: "filter function invalid", v: fun_filter)
  end

  def filter_workflow_pipeline_singleton_entry(pipeline, fun_filter) do
    with {:ok, pipeline} <- pipeline |> filter_workflow_pipeline(fun_filter) do
      case pipeline |> length do
        1 ->
          {:ok, pipeline |> hd}

        n ->
          new_error_result(m: "pipeline entries too few or too many; expected 1", v: n)
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def filter_workflow_pipeline_by_singleton(pipeline) do
    with {:ok, pipeline} <- pipeline |> HASWU.validate_workflow_pipeline() do
      case pipeline |> length do
        1 ->
          {:ok, pipeline |> hd}

        n ->
          new_error_result(m: "pipeline too small or too large; expected 1", v: n)
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def filter_workflow_pipeline_by_index(pipeline, index)

  def filter_workflow_pipeline_by_index(pipeline, index) when is_integer(index) do
    with {:ok, pipeline} <- pipeline |> HASWU.validate_workflow_pipeline() do
      pipeline
      |> Enum.at(index, @harnais_form_schatten_value_not_set)
      |> case do
        @harnais_form_schatten_value_not_set ->
          new_error_result(m: "filter index #{inspect(index)} not found", v: pipeline)

        value ->
          {:ok, value}
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def filter_workflow_pipeline_by_index(_value, index) do
    new_error_result(m: "filter index invalid", v: index)
  end

  def filter_workflow_pipeline_by_verb(pipeline, verb)

  def filter_workflow_pipeline_by_verb([], _verb) do
    {:ok, []}
  end

  def filter_workflow_pipeline_by_verb(pipeline, verb) do
    pipeline
    |> filter_workflow_pipeline(fn
      {^verb, _, _} -> true
      _ -> false
    end)
  end

  def filter_workflow_pipeline_by_field(pipeline, field)

  def filter_workflow_pipeline_by_field([], _field) do
    {:ok, []}
  end

  def filter_workflow_pipeline_by_field(pipeline, field) do
    pipeline
    |> filter_workflow_pipeline(fn
      {_, ^field, _} -> true
      _ -> false
    end)
  end

  def filter_workflow_pipeline_by_last_field(pipeline, field) do
    with {:ok, pipeline} <- pipeline |> filter_workflow_pipeline_by_field(field) do
      {:ok, pipeline |> List.last()}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def filter_workflow_pipeline_by_verb_field(pipeline, verb, field) do
    with {:ok, pipeline} <- pipeline |> filter_workflow_pipeline_by_verb(verb),
         {:ok, _pipeline} = result <- pipeline |> filter_workflow_pipeline_by_field(field) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def filter_workflow_pipeline_by_singleton_verb_field(pipeline, verb, field) do
    with {:ok, pipeline} <- pipeline |> filter_workflow_pipeline_by_verb_field(verb, field),
         {:ok, _tuple} = result <- pipeline |> filter_workflow_pipeline_by_singleton do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def filter_workflow_pipeline_by_last_verb_field(pipeline, verb, field) do
    with {:ok, pipeline} <- pipeline |> filter_workflow_pipeline_by_verb_field(verb, field),
         {:ok, _tuple} = result <- pipeline |> filter_workflow_pipeline_by_index(-1) do
      result
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
