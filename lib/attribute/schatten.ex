defmodule Harnais.Form.Attribute.Schatten do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      use Plymio.Fontais.Attribute

      @harnais_form_schatten_value_not_set @plymio_fontais_the_unset_value

      @harnais_form_schatten_value_form_initial @harnais_form_schatten_value_not_set

      @harnais_form_schatten_value_workflow_pipeline_initial @harnais_form_schatten_value_not_set

      @harnais_form_schatten_value_transform_opts_initial @harnais_form_schatten_value_not_set

      @harnais_form_schatten_value_eval_binding_initial @harnais_form_schatten_value_not_set
      @harnais_form_schatten_value_eval_result_initial @harnais_form_schatten_value_not_set
      @harnais_form_schatten_value_eval_opts_initial @harnais_form_schatten_value_not_set

      @harnais_form_schatten_field_workflow_pipeline :workflow_pipeline

      @harnais_form_schatten_field_form :form

      @harnais_form_schatten_field_transform_opts :transform_opts

      @harnais_form_schatten_field_eval_binding :eval_binding
      @harnais_form_schatten_field_eval_result :eval_result
      @harnais_form_schatten_field_eval_opts :eval_opts

      @harnais_form_schatten_key_field_name :field

      @harnais_form_schatten_key_expect_error :expect_error

      @harnais_form_schatten_key_expect_result :expect_result

      @harnais_form_schatten_key_expect_text :expect_text
      @harnais_form_schatten_key_expect_texts :expect_texts

      @harnais_form_schatten_key_expect_form :expect_form
      @harnais_form_schatten_key_expect_forms :expect_forms

      @harnais_form_schatten_key_verb :verb

      @harnais_form_schatten_key_form :form
      @harnais_form_schatten_key_forms :forms

      @harnais_form_schatten_field_alias_workflow_pipeline {@harnais_form_schatten_field_workflow_pipeline,
                                                            nil}

      @harnais_form_schatten_field_alias_form {@harnais_form_schatten_field_form, [:f, :forms]}

      @harnais_form_schatten_field_alias_eval_binding {@harnais_form_schatten_field_eval_binding,
                                                       [:b, :binding]}
      @harnais_form_schatten_field_alias_eval_result {@harnais_form_schatten_field_eval_result,
                                                      []}
      @harnais_form_schatten_field_alias_eval_opts {@harnais_form_schatten_field_eval_opts, [:b]}

      @harnais_form_schatten_field_alias_transform_opts {@harnais_form_schatten_field_transform_opts,
                                                         [:forms_edit]}

      @harnais_form_schatten_workflow_pipeline_edit_verb_add_tail :add_tail
      @harnais_form_schatten_workflow_pipeline_edit_verb_add_head :add_head
      @harnais_form_schatten_workflow_pipeline_edit_verb_filter :filter
      @harnais_form_schatten_workflow_pipeline_edit_verb_reject :reject
      @harnais_form_schatten_workflow_pipeline_edit_verb_collate :collate

      @harnais_form_schatten_workflow_verb_build :build
      @harnais_form_schatten_workflow_verb_produce :produce
      @harnais_form_schatten_workflow_verb_express :express
      @harnais_form_schatten_workflow_verb_expect :expect
      @harnais_form_schatten_workflow_verb_actual :actual

      @harnais_form_schatten_workflow_verbs_order [
        @harnais_form_schatten_workflow_verb_build,
        @harnais_form_schatten_workflow_verb_expect,
        @harnais_form_schatten_workflow_verb_actual,
        @harnais_form_schatten_workflow_verb_express,
        @harnais_form_schatten_workflow_verb_produce
      ]

      @harnais_form_schatten_field_bootstrap_form :bootstrap_form
      @harnais_form_schatten_field_bootstrap_forms :bootstrap_forms
      @harnais_form_schatten_field_transform_form :transform_form
      @harnais_form_schatten_field_transform_forms :transform_forms

      @harnais_form_schatten_field_result :result
      @harnais_form_schatten_field_error :error
      @harnais_form_schatten_field_text :text
      @harnais_form_schatten_field_texts :texts
      @harnais_form_schatten_field_format_text :format_text
      @harnais_form_schatten_field_format_texts :format_texts
      @harnais_form_schatten_field_form :form
      @harnais_form_schatten_field_forms :forms

      @harnais_form_schatten_fields_known [
        @harnais_form_schatten_field_result,
        @harnais_form_schatten_field_error,
        @harnais_form_schatten_field_text,
        @harnais_form_schatten_field_texts,
        @harnais_form_schatten_field_format_text,
        @harnais_form_schatten_field_format_texts,
        @harnais_form_schatten_field_form,
        @harnais_form_schatten_field_forms,
        @harnais_form_schatten_field_bootstrap_form,
        @harnais_form_schatten_field_bootstrap_forms,
        @harnais_form_schatten_field_transform_form,
        @harnais_form_schatten_field_transform_forms,
        :custom
      ]

      @harnais_form_schatten_workflow_pipeline_default @harnais_form_schatten_value_not_set

      @harnais_form_test_forms_default_opts [
        # supply an empty binding
        {@harnais_form_schatten_field_eval_binding, []},

        # defaults expresses
        {@harnais_form_schatten_workflow_verb_express,
         [
           @harnais_form_schatten_field_result,
           @harnais_form_schatten_field_form
         ]}
      ]

      @harnais_form_schatten_error_text_compare_failed "compare expect actual failed"
      @harnais_form_schatten_error_text_forms_generator_failed "forms generator function failed"
    end
  end
end
