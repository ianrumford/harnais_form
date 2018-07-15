defmodule Harnais.Form.Schatten.Workflow.Normalise do
  @moduledoc false

  require Plymio.Fontais.Option
  alias Harnais.Form.Schatten, as: HAS
  alias Harnais.Form.Utility, as: HAU

  use Harnais.Error.Attribute
  use Harnais.Form.Attribute.Schatten

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Guard,
    only: [
      is_value_set: 1,
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

  import Plymio.Fontais.Form,
    only: [
      form_validate: 1,
      forms_validate: 1,
      forms_edit: 2
    ]

  import Plymio.Funcio.Enum.Map.Collate,
    only: [
      map_concurrent_collate0_enum: 2
    ]

  def normalise_workflow_pipeline_transform_form(
        %HAS{@harnais_form_schatten_field_transform_opts => transform_opts} = state,
        {verb, field, value}
      )
      when field == @harnais_form_schatten_field_form do
    transform_opts
    |> is_value_set
    |> case do
      true ->
        with {:ok, transform_opts} <- transform_opts |> opts_validate,
             {:ok, [form]} <- value |> forms_edit(transform_opts) do
          {:ok, {{verb, field, form}, state}}
        else
          {:error, %{__exception__: true}} = result -> result
        end

      _ ->
        {:ok, {{verb, field, value}, state}}
    end
  end

  def normalise_workflow_pipeline_field_transform_forms(
        %HAS{@harnais_form_schatten_field_transform_opts => transform_opts} = state,
        {verb, field, value}
      )
      when field == @harnais_form_schatten_field_forms do
    transform_opts
    |> is_value_set
    |> case do
      true ->
        with {:ok, transform_opts} <- transform_opts |> opts_validate,
             {:ok, forms} <- value |> forms_edit(transform_opts) do
          {:ok, {{verb, field, forms}, state}}
        else
          {:error, %{__exception__: true}} = result -> result
        end

      _ ->
        {:ok, {{verb, field, value}, state}}
    end
  end

  def normalise_workflow_pipeline_tuple(tuple)

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_transform_form do
    {:ok, {verb, field, &normalise_workflow_pipeline_transform_form/2}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_transform_forms do
    {:ok, {verb, field, &normalise_workflow_pipeline_field_transform_forms/2}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_form do
    fun = fn {verb, field, form} ->
      with {:ok, form} <- form |> form_validate do
        {:ok, {verb, field, form}}
      else
        {:error, %{__exception__: true}} = result -> result
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_forms do
    fun = fn {verb, field, forms} ->
      with {:ok, forms} <- forms |> forms_validate do
        {:ok, {verb, field, forms}}
      else
        {:error, %{__exception__: true}} = result -> result
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_text do
    {:ok,
     {verb, field, fn {verb, _field, form} -> {:ok, {verb, field, form |> Macro.to_string()}} end}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_texts do
    {:ok,
     {verb, field,
      fn {verb, _field, forms} ->
        {:ok, {verb, field, forms |> Enum.map(&Macro.to_string/1)}}
      end}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_format_text do
    fun = fn {verb, _field, text} ->
      with {:ok, format_text} <- text |> HAU.form_format() do
        {:ok, {verb, field, format_text}}
      else
        {:error, %{__exception__: true}} = result -> result
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_format_texts do
    fun = fn {verb, _field, texts} ->
      with {:ok, format_texts} <-
             texts
             |> map_concurrent_collate0_enum(&HAU.form_format/1) do
        {:ok, {verb, field, format_texts}}
      else
        {:error, %{__exception__: true}} = result -> result
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, value})
      when is_value_unset(value) and verb == @harnais_form_schatten_workflow_verb_build and
             field == @harnais_form_schatten_field_error do
    fun = fn {verb, _field, error} ->
      cond do
        Exception.exception?(error) ->
          {:ok, error}

        is_binary(error) ->
          {:ok, error}

        true ->
          new_error_result(m: "error invalid", v: error)
      end
      |> case do
        {:error, %{__exception__: true}} = result -> result
        {:ok, error} -> {:ok, {verb, field, error}}
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, expect_value})
      when verb == @harnais_form_schatten_workflow_verb_expect and
             field == @harnais_form_schatten_field_error and is_value_set(expect_value) and
             not (is_function(expect_value, 1) or is_function(expect_value, 2)) do
    with {:ok, expect_message} <- expect_value |> normalise_exception_message do
      fun = fn {verb, field, actual_value} ->
        with {:ok, actual_message} <- actual_value |> normalise_exception_message do
          case expect_message == actual_message do
            true ->
              {:ok, {verb, field, actual_value}}

            _ ->
              new_error_result(
                message_function: &opts_compare_expect_actual_fun_message1/1,
                t: @harnais_error_value_field_type_value,
                m: "compare expect actual failed",
                r: @harnais_error_reason_mismatch,
                i: field,
                v1: actual_message,
                v2: expect_message
              )
          end
        else
          {:error, %{__exception__: true}} = result -> result
        end
      end

      {:ok, {verb, field, fun}}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def normalise_workflow_pipeline_tuple({verb, field, expect_value})
      when verb == @harnais_form_schatten_workflow_verb_expect and is_function(expect_value, 1) do
    fun = fn {_verb, field, actual_value} = actual_tuple ->
      actual_tuple
      |> expect_value.()
      |> HAU.truthy0_result()
      |> case do
        {:ok, _} ->
          {:ok, actual_tuple}

        # rewrite error if a match error
        {:error, %MatchError{}} ->
          new_error_result(
            message_function: &opts_compare_expect_actual_fun_message2/1,
            t: @harnais_error_value_field_type_value,
            m: @harnais_form_schatten_error_text_compare_failed,
            r: @harnais_error_reason_mismatch,
            i: field,
            v1: actual_value
          )

        {:error, %{__struct__: _}} = result ->
          result
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, expect_value})
      when verb == @harnais_form_schatten_workflow_verb_expect and is_function(expect_value, 2) do
    fun = fn %HAS{} = state, {_verb, field, actual_value} = actual_tuple ->
      expect_value.(state, actual_tuple)
      |> HAU.truthy0_result()
      |> case do
        {:ok, _} ->
          {:ok, {actual_tuple, state}}

        # rewrite error is a match error
        {:error, %MatchError{}} ->
          new_error_result(
            message_function: &opts_compare_expect_actual_fun_message2/1,
            t: @harnais_error_value_field_type_value,
            m: @harnais_form_schatten_error_text_compare_failed,
            r: @harnais_error_reason_mismatch,
            i: field,
            v1: actual_value
          )

        {:error, %{__struct__: _}} = result ->
          result
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({verb, field, expect_value})
      when verb == @harnais_form_schatten_workflow_verb_expect and is_value_set(expect_value) and
             not (is_function(expect_value, 1) or is_function(expect_value, 2)) do
    fun = fn {verb, _field, actual_value} ->
      case expect_value == actual_value do
        true ->
          {:ok, {verb, field, actual_value}}

        _ ->
          new_error_result(
            message_function: &opts_compare_expect_actual_fun_message1/1,
            t: @harnais_error_value_field_type_value,
            m: @harnais_form_schatten_error_text_compare_failed,
            r: @harnais_error_reason_mismatch,
            i: field,
            v1: actual_value,
            v2: expect_value
          )
      end
    end

    {:ok, {verb, field, fun}}
  end

  def normalise_workflow_pipeline_tuple({_verb, _field, _value} = tuple) do
    {:ok, tuple}
  end

  defp opts_compare_expect_actual_fun_message1(%Harnais.Error{
         @harnais_error_field_location => field,
         @harnais_error_field_value2 => expect,
         @harnais_error_field_value1 => actual
       }) do
    {:ok,
     "compare expect actual failed, got: field: #{inspect(field)}, expect: #{inspect(expect)}; actual: #{
       inspect(actual)
     }"}
  end

  defp opts_compare_expect_actual_fun_message2(%Harnais.Error{
         @harnais_error_field_location => field,
         @harnais_error_field_value1 => actual
       }) do
    {:ok,
     "compare expect actual function failed, got: field: #{inspect(field)}, actual: #{
       inspect(actual)
     }"}
  end

  defp normalise_exception_message(value) do
    cond do
      is_binary(value) ->
        {:ok, value}

      Exception.exception?(value) ->
        {:ok, value |> Exception.message()}

      true ->
        new_error_result(m: "exception message invalid", v: value)
    end
  end
end
