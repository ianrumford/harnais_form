defmodule Harnais.Form.Attribute do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      use Plymio.Fontais.Attribute

      @harnais_form_opts_key_edit_pipeline :edit_pipeline
      @harnais_form_opts_key_edit_regex :edit_regex

      @harnais_form_aliases_opts_transform_ast @plymio_fontais_form_edit_keys
                                               |> Enum.map(fn key -> {key, nil} end)

      # processing keys for harnais_form_test_forms
      @harnais_form_key_transform_ast :transform_ast
      @harnais_form_key_eval_quoted :eval_quoted

      # the processing order for harnais_form_test_forms
      @harnais_form_order_ast_eval_keys [
        @harnais_form_key_transform_ast,
        @harnais_form_key_eval_quoted
      ]

      @harnais_form_key_transform_opts :transform_opts
      @harnais_form_key_eval_opts :eval_opts
      @harnais_form_key_eval_binding :eval_binding
    end
  end
end
