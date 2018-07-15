defmodule Harnais.Form.Schatten.Workflow.Depend do
  @moduledoc false

  require Plymio.Fontais.Option
  alias Harnais.Form.Schatten.Workflow.Edit, as: HASWE
  alias Harnais.Form.Schatten.Workflow.Utility, as: HASWU

  use Harnais.Form.Attribute.Schatten

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Utility,
    only: [
      list_wrap_flat_just: 1
    ]

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  @workflow_dependencies %{
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_transform_form} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_bootstrap_form,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_transform_forms} =>
      [
        {
          @harnais_form_schatten_workflow_verb_build,
          @harnais_form_schatten_field_bootstrap_form,
          @harnais_form_schatten_value_not_set
        }
      ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_form} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_transform_form,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_forms} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_transform_forms,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_text} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_form,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_texts} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_forms,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_format_text} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_text,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_format_texts} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_texts,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_build, @harnais_form_schatten_field_result} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_form,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_form} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_form,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_forms} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_forms,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_text} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_text,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_texts} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_texts,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_format_text} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_format_text,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_format_texts} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_format_texts,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_result} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_result,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_expect, @harnais_form_schatten_field_error} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_error,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_express, @harnais_form_schatten_field_form} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_form,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_express, @harnais_form_schatten_field_forms} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_forms,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_express, @harnais_form_schatten_field_text} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_text,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_express, @harnais_form_schatten_field_texts} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_texts,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_express, @harnais_form_schatten_field_format_text} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_format_text,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_express, @harnais_form_schatten_field_format_texts} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_format_texts,
        @harnais_form_schatten_value_not_set
      }
    ],
    {@harnais_form_schatten_workflow_verb_express, @harnais_form_schatten_field_result} => [
      {
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_field_result,
        @harnais_form_schatten_value_not_set
      }
    ]
  }

  defp dependent_workflow_entry_worker(verb_field_value, dict)

  defp dependent_workflow_entry_worker({verb, field, _value}, dict) do
    dict
    |> Map.has_key?({verb, field})
    |> case do
      true ->
        dict
        |> Map.get({verb, field})
        |> list_wrap_flat_just
        |> Enum.reduce_while(
          [],
          fn vfa, pipeline ->
            with {:ok, dependencies} <- vfa |> dependent_workflow_entry_worker(dict),
                 {:ok, pipeline} <-
                   pipeline
                   |> HASWE.edit_workflow_pipeline([
                     {@harnais_form_schatten_workflow_pipeline_edit_verb_add_head, dependencies},
                     {@harnais_form_schatten_workflow_pipeline_edit_verb_add_tail, vfa}
                   ]),
                 true <- true do
              {:cont, pipeline}
            else
              {:error, %{__struct__: _}} = result -> {:halt, result}
            end
          end
        )
        |> case do
          {:error, %{__exception__: true}} = result -> result
          pipeline -> pipeline |> HASWU.validate_workflow_pipeline()
        end

      _ ->
        {:ok, []}
    end
  end

  def dependent_workflow_entry(verb_field_value, dict \\ @workflow_dependencies)

  def dependent_workflow_entry({verb, field, value}, dict) do
    with {:ok, dependencies} <- {verb, field, value} |> dependent_workflow_entry_worker(dict),
         true <- true do
      {:ok, dependencies}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end
end
