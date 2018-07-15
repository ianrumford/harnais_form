defmodule Harnais.Form.Schatten do
  @moduledoc ~S"""
  A specialised harness for testing Quoted Forms.

  This module does the "heavy lift" for
  `Harnais.Form.harnais_form_test_forms/2` but can be used stand-alone
  by calling `produce_schatten/2` directly.

  See `Harnais.Form` for overview and other documentation terms.

  ## Documentation Terms

  ### *schatten*

  An instance of the module's `struct`.

  ## Production Overview

  `produce_schatten/2` runs a workflow  of dependent phases with each phase assocated with a
  field (e.g. *forms*, *text*, *format text*) and each phase having
  one or more stages identified by a *verb* (e.g. `build`, `express`, `actual`, `expect`).

  To explain, consider an example where a *forms* is passed to
  `produce_schatten/2` and needs to produce the code formatted
  by the Elixir code formatter.

  To illustrate, here are the example forms:

       [quote(do: def add1(x, do: x + 1)), quote(do: def sub1(x, do: x - 1))]

  First the *schatten* must `build` a single *form* from the *forms*
  using `Kernel.unquote_splicing/1`. (The single *form* is a block (`:__block__`) and
  showing it here just clutters the explanation.)

  Next it must `build` the  *text* from the single *form* using `Macro.to_text/1`.

       "(\n  def(add1(x) do\n    x + 1\n  end)\n  def(sub1(x) do\n    x - 1\n  end)\n)"

  Then the *text* must be used to `build` the *format text* using `Code.format_string!/1` (and then joining the iodata):

       "def(\n  add1(x) do\n    x + 1\n  end\n)\n\ndef(\n  sub1(x) do\n    x - 1\n  end\n)"

  Finally the *schatten* must `express` the *format text* into the *product* as e.g.

      [format_text: "def(\n  add1(x) do\n    x + 1\n  end\n)\n\ndef(\n  sub1(x) do\n    x - 1\n  end\n)"]

  Here is the doctest that shows the above explanation in action:

      iex> forms = [quote(do: def add1(x, do: x + 1)), quote(do: def sub1(x, do: x - 1))]
      ...> {:ok, {[format_text: format_text], _schatten}} = forms
      ...> |> produce_schatten(express: :format_text)
      ...> format_text
      "def(\n  add1(x) do\n    x + 1\n  end\n)\n\ndef(\n  sub1(x) do\n    x - 1\n  end\n)"

  This silly example shows the use of a function to `:express` the *format text* - here it uppercases it:

      iex> forms = [quote(do: def add1(x, do: x + 1)), quote(do: def sub1(x, do: x - 1))]
      ...> {:ok, {[format_text: format_text], _schatten}} = forms
      ...> |> produce_schatten(express: [
      ...>     {:format_text, fn {:actual,:format_text,format_text} -> {:ok, format_text |> String.upcase} end}])
      ...> format_text
      "DEF(\n  ADD1(X) DO\n    X + 1\n  END\n)\n\nDEF(\n  SUB1(X) DO\n    X - 1\n  END\n)"

  If wanted, the input *forms* could be `express`-ed also so the *product* would contain:

      [format_text: "def(\n  add1(x) do\n    x + 1\n  end\n)\n\ndef(\n  sub1(x) do\n    x - 1\n  end\n)",
       forms: [quote(do: def add1(x, do: x + 1)), quote(do: def sub1(x, do: x - 1))]]

  Production also allows the actual value of a field to be
  compared with an expected value using the `:expect` verb.  This
  variant of the doctest above just confirms the *format text* is as expected
  but does not bother to `express` anything (so the product is empty).

      iex> forms = [quote(do: def add1(x, do: x + 1)), quote(do: def sub1(x, do: x - 1))]
      ...> {:ok, {product, _schatten}} = forms
      ...> |> produce_schatten(expect: [
      ...>   format_text: "def(\n  add1(x) do\n    x + 1\n  end\n)\n\ndef(\n  sub1(x) do\n    x - 1\n  end\n)"])
      ...> product
      []

  If the `:expect`-ed value does not match to `:actual` value, an
  error result will be returned. This doctest exports
  (`Harnais.Error.export_exception/2`) the error to show the details of the error.

      iex> forms = [quote(do: def add1(x, do: x + 1)), quote(do: def sub1(x, do: x - 1))]
      ...> {:error, error} = forms
      ...> |> produce_schatten(expect: [format_text: "this is wrong"])
      ...> error |> Harnais.Error.export_exception
      {:ok, [error: [[m: "compare expect actual failed",
                      r: :mismatch,
                      t: :value,
                      l: :format_text,
                      v1: "def(\n  add1(x) do\n    x + 1\n  end\n)\n\ndef(\n  sub1(x) do\n    x - 1\n  end\n)",
                      v2: "this is wrong"]]]}

  ## Production Fields

  `produce_schatten/2` has these *standard fields* that it knows how to derive from the *form/forms*:

  | Field | Purpose |
  | :---  | :---    |
  | `result` | *the first element in the 2tuple returned by `Code.eval_quoted/3`* |
  | `error` | *the error - Exception is binary* |
  | `form` | *the form or forms as a single form* |
  | `forms` | *the form or forms as a list of forms* |
  | `text` | *the string from calling `Macro.to_string/1` on the single form* |
  | `texts` | *the list of strings from calling `Macro.to_string/1` on each form* |
  | `format_text` | *the string from calling `Code.format_string!/1` on the *text* |
  | `format_texts` | *the list of strings from calling `Code.format_string!/1` on each *text* |

  ## Production Workflow

  Production is a simple workflow represented by a pipeline of one or
  more 3tuples where the first element is the *verb* (e.g. `:actual`, `:build`,
  `:express`), the second the *field* (e.g. *format text*) , and the third a value whose
  meaning is specific to to verb/field combination.

  When the workflow is run, each 3tuple usually adds one or more 3tuples to the end of the pipeline. For example

       {:build, :format_text, build_fun}

  finds the last 3tuple with `{:actual, :text, text}` e.g.

       {:actual, :text, "(\n  def(add1(x) do\n    x + 1\n  end)\n  def(sub1(x) do\n    x - 1\n  end)\n)"}

  passes the *text* to `Code.format_string!/1`, and then adds the
  *format_text* 3tuple to the end of the pipeline:

       {:actual, :format_text, "def(\n  add1(x) do\n    x + 1\n  end\n)\n\ndef(\n  sub1(x) do\n    x - 1\n  end\n)"}

  Similary running `{:express, :format_text, express_fun}` finds the last
  `{:actual, :format_text, format_text}` and adds `{:produce, :format_text, format_text}`
  to the end of the pipeline.

  Some verbs are generated automatically: for example `:express`-ing the
  *text* field generates an automatic *build* for *text* (which in
  turn generates a *build* for *form*).

  The last instance of a 3tuple for each verb/field combination takes
  precedence.

  ### Production Workflow 3Tuple: {:actual, field, value}

  The `:actual` *verb* adds the `value` for the `field` to the pipeline as the literal 3tuple
  `{:actual, field, value}`.

  ### Production Workflow 3Tuple : {:build, field, build_fun}

  The `:build` *verb* finds the _last_ `:actual` value of the *field*
  in the *pipeline* and calls the `build_fun`.

  The `:build` 3tuple is a [Production Transform Tuple](#module-production-transform-tuples).

  All of the *standard fields* have a default build function.

  A `:build` can be (and usually is) generated automatically by
  e.g. an `:expect` or `:express` for a field (see below).

  ### Production Workflow 3Tuple: {:express, field, express_fun}

  The `:express` *verb* first finds the _last_ `{:actual, field, value}` 3tuple
  in the *pipeline* and calls the `express_fun`.

  The `:express` 3tuple is a [Production Transform Tuple](#module-production-transform-tuples).

  ### Production Workflow 3Tuple: {:expect, field, expect_value}

  The `:expect` *verb* first finds the _last_ `{:actual, field, actual_value}` 3tuple
  in the *pipeline*.

  If the `expect_value` is a function, the 3tuple is treated as a [transform tuple](#module-product-transform-tuples)
  *but* the return is normalised to *pattern 0 truthy result* (See `Harnais.Form.Utility.truthy0_result/1`).

  Otherwise the `expect_value` is just compared (`Kernel.==/2`) with the `actual_value`.

  If the compare does not return *truthy*, the workflow is aborted and `{:error, error}` returned.

  ## Production Product

  The *product* is created from the  *last* 3tuple for each `field`
  where the `verb` is `:produce` and dropping the *verb*.

  `:build` *verb* 3tuples are run before any other *verbs* and in
  the order given.

  ## Production Transform Tuples

  The value in the 3tuple for some *verbs* (e.g. `build`, `express`)
  can be either *the unset value* or an arity 1 or 2 function.

  When the value is *the unset value*, the default transform function
  is used.  For example, the default function for `:build`-ing the
  *text* field from the *form* field calls `Macro.to_string/1`.

  If the value is an arity 1 function, it is passed (usually) the
  `:actual` tuple. (So `:build`-ing the *text* will be passed
  `{:actual, :form, form}`.). The function must return either
  e.g.  `{:ok, {:actual, :text, text}}` or `{:ok, text}`.

  If the value is an arity 2 function, it is passed the *schatten* and (usually) the
  `:actual` tuple. The function must return either e.g. `{:ok, {:actual, :text, text}, schatten}`,
  `{:ok, {:actual, :text, text}}` or `{:ok, text}`.

  ## Production Opts

  The allowed keys in the production *opts* are:

  ### Production Opts key: `:transform_opts`

    The forms, together with the value of `:transform_opts` are passed to
    `harnais_form_transform_forms/2` and the transformed forms (re)added to the pipeline.

  ### Production Opts key: `:eval_binding`

    The value of `:eval_binding` is used as the 2nd argument in the call to `Code.eval_quoted/3`. Default is an empty list.

  ### Production Opts Key: `:eval_opts`

    The value of `:eval_opts` is used as the 3rd argument in the call to `Code.eval_quoted/3`. Default is `__ENV__`.
  """

  require Plymio.Fontais.Option
  use Plymio.Codi
  alias Harnais.Form.Utility, as: HAU

  alias Harnais.Form.Schatten.Workflow.Utility, as: HASWU
  alias Harnais.Form.Schatten.Workflow.Depend, as: HASWD
  alias Harnais.Form.Schatten.Workflow.Filter, as: HASWF
  alias Harnais.Form.Schatten.Workflow.Edit, as: HASWE
  alias Harnais.Form.Schatten.Workflow.Run, as: HASWR
  use Harnais.Error.Attribute
  use Harnais.Form.Attribute
  use Harnais.Form.Attribute.Schatten

  @codi_opts [
    {@plymio_codi_key_vekil, Plymio.Vekil.Codi.__vekil__()}
  ]

  import Harnais.Error,
    only: [
      new_error_result: 1
    ],
    warn: false

  import Plymio.Fontais.Guard,
    only: [
      is_value_set: 1,
      is_filled_list: 1
    ]

  import Plymio.Fontais.Option,
    only: [
      opts_validate: 1,
      opts_create_aliases_dict: 1,
      opts_canonical_keys: 2
    ]

  import Plymio.Funcio.Enum.Reduce,
    only: [
      reduce0_enum: 3,
      reduce2_enum: 3
    ]

  @harnais_form_keys_opts_transform_ast_aliases HAU.opts_ast_transform_keys_aliases()

  @type t :: %__MODULE__{}
  @type form :: Harnais.ast()
  @type forms :: Harnais.asts()
  @type kv :: {any, any}
  @type opts :: Harnais.opts()
  @type error :: Harnais.error()

  @harnais_form_schatten_kvs_aliases @harnais_form_aliases_opts_transform_ast ++
                                       [
                                         @harnais_form_schatten_field_alias_workflow_pipeline,
                                         @harnais_form_schatten_field_alias_form,
                                         @harnais_form_schatten_field_alias_eval_binding,
                                         @harnais_form_schatten_field_alias_eval_result,
                                         @harnais_form_schatten_field_alias_eval_opts,
                                         @harnais_form_schatten_field_alias_transform_opts,
                                         {@harnais_form_schatten_workflow_verb_build, []},
                                         {@harnais_form_schatten_workflow_verb_actual, []},
                                         {@harnais_form_schatten_workflow_verb_expect,
                                          [:compare]},
                                         {@harnais_form_schatten_workflow_verb_express, []},
                                         {@harnais_form_schatten_workflow_verb_produce, []}
                                       ]

  @harnais_form_schatten_dict_aliases @harnais_form_schatten_kvs_aliases
                                      |> opts_create_aliases_dict

  @doc false

  def update_canonical_opts(opts, dict \\ @harnais_form_schatten_dict_aliases) do
    opts |> opts_canonical_keys(dict)
  end

  @doc false

  def opts_maybe_canonical_keys(opts, dict \\ @harnais_form_schatten_dict_aliases) do
    opts |> opts_maybe_canonical_keys(dict)
  end

  @doc false

  def opts_take_canonical_keys(opts, dict \\ @harnais_form_schatten_dict_aliases) do
    with {:ok, opts} <- opts |> opts_maybe_canonical_keys(dict) do
      {:ok, opts |> Keyword.take(dict |> Map.keys())}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @harnais_form_schatten_defstruct [
    {@harnais_form_schatten_field_workflow_pipeline,
     @harnais_form_schatten_workflow_pipeline_default},
    {@harnais_form_schatten_field_form, @harnais_form_schatten_value_form_initial},
    {@harnais_form_schatten_field_eval_binding,
     @harnais_form_schatten_value_eval_binding_initial},
    {@harnais_form_schatten_field_eval_result, @harnais_form_schatten_value_eval_result_initial},
    {@harnais_form_schatten_field_eval_opts, @harnais_form_schatten_value_eval_opts_initial},
    {@harnais_form_schatten_field_transform_opts,
     @harnais_form_schatten_value_transform_opts_initial}
  ]

  defstruct @harnais_form_schatten_defstruct

  @doc ~S"""
  `produce_schatten/2` expects its first argument to be a *forms*.

  The second argument can either be a pre-created *schatten* or an *opts*
  that will be passed to `new/1` to create a *schatten*.

  It returns `{:ok, {product, %__MODULE__{} = schatten}}` or
  `{:error, error}` where `product` will be a `Keyword`.

  ## Examples

  The various ways the *verbs* can be combined makes for a large number of use cases. These are just a selection.

  This example doesn't do anything; the product is empty.

      iex> {:ok, {[], schatten}} = 42 |> produce_schatten
      ...> match?(%Harnais.Form.Schatten{}, schatten)
      true

  Here the expected form is tested but there are no *expressed* fields so again the product is empty.

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {[], schatten}} = form
      ...> |> produce_schatten(expect: [form: form])
      ...> match?(%Harnais.Form.Schatten{}, schatten)
      true

  To express the *form* in the *product*:

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {[form: ^form] = product, _schatten}} = form
      ...> |> produce_schatten(expect: [form: form], express: :form)
      ...> product
      [form: quote(do: x = x + 1)]

  Here a single form is expressed as a list of forms and texts:

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {[forms: [^form], texts: texts], _schatten}} = form
      ...> |> produce_schatten(expect: [form: form], express: [:forms, :texts])
      ...> texts
      ["x = x + 1"]

  This example includes a `:binding` and `expect`s the `:result` to be 63.

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {[result: 8, text: text], _schatten}} = form
      ...> |> produce_schatten(binding: [x: 7],
      ...>   expect: [result: 8], express: [:result, :text])
      ...> text
      "x = x + 1"

  The expect value can be an arity 1 function that is passed the
  actula value and should return a *pattern 0 truthy value* (See
  `Harnais.Form.Utility.truthy0_result/1`). First example show the expect function returning *truthy*:

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {[result: 8, text: text], _schatten}} = form
      ...> |> produce_schatten(binding: [x: 7],
      ...>   expect: [result: fn _actual -> true end], express: [:result, :text])
      ...> text
      "x = x + 1"

  Second example shows the expect function returning `nil` (*falsy*):

      iex> form = quote(do: x = x + 1)
      ...> {:error, error} = form
      ...> |> produce_schatten(binding: [x: 7],
      ...>   expect: [result: fn _actual -> nil end], express: [:result, :text])
      ...> error |> Exception.message
      "compare expect actual function failed, got: field: :result, actual: 8"

  Multiple forms and a *binding* make for a more interesting example:

      iex> forms = [
      ...>   quote(do: x = x + 1),
      ...>   quote(do: x = x * x),
      ...>   quote(do: x = x - 1),
      ...> ]
      ...> {:ok, {[result: 63, texts: texts], _schatten}} = forms
      ...> |> produce_schatten(binding: [x: 7],
      ...>   expect: [result: 63], express: [:result, :texts])
      ...> texts
      ["x = x + 1", "x = x * x", "x = x - 1"]

  Or even multiple forms as a single form and as *text*:

      iex> forms = [
      ...>   quote(do: x = x + 1),
      ...>   quote(do: x = x * x),
      ...>   quote(do: x = x - 1),
      ...> ]
      ...> {:ok, {[result: 63, form: form], _schatten}} = forms
      ...> |> produce_schatten(binding: [x: 7],
      ...>   expect: [result: 63], express: [:result, :form])
      ...> form |> Macro.to_string
      "(\n  x = x + 1\n  x = x * x\n  x = x - 1\n)"

      iex> forms = [
      ...>   quote(do: x = x + 1),
      ...>   quote(do: x = x * x),
      ...>   quote(do: x = x - 1),
      ...> ]
      ...> {:ok, {[result: 63, text: text], _schatten}} = forms
      ...> |> produce_schatten(binding: [x: 7],
      ...>   expect: [result: 63], express: [:result, :text])
      ...> text
      "(\n  x = x + 1\n  x = x * x\n  x = x - 1\n)"

  The function supports transforming the *forms* before production.
  The options supported by `Plymio.Fontais.Form.forms_edit/2` can
  be given. In this example the forms are postwalked to change `x` to
  `a`.

      iex> forms = [
      ...>   quote(do: x = x + 1),
      ...>   quote(do: x = x * x),
      ...>   quote(do: x = x - 1),
      ...> ]
      ...> {:ok, {[result: 63, text: text], _schatten}} = forms
      ...> |> produce_schatten(binding: [a: 7],
      ...>   postwalk: fn
      ...>    {:x, [], m} when is_atom(m) -> Macro.var(:a, m)
      ...>    passthru -> passthru
      ...>   end,
      ...>   expect: [result: 63], express: [:result, :text])
      ...> text
      "(\n  a = a + 1\n  a = a * a\n  a = a - 1\n)"

  The default `:build` function for the *standard fields* can be
  overidden by supplying an explicit function. Here the builder
  function for `:forms` is given explicitly and is passed the
  *schatten* and the (lform) `:actual` *verb* 3tuple for the `:forms`
  field. It must return `{:ok, forms}` or `{:error, error}`. Here the
  three initial `x` forms are "built" into two `a` forms.

  Its important to note that once production has started, the single form
  and multiple forms can diverge.  In this example the `result` has been
  otained from evaluating (`Code.eval_quoted/3`) the single form which
  is still the "reduced" (`Kernel.SpecialForms.unquote_splicing/1`)
  original list of three `forms`.

      iex> forms = [
      ...>   quote(do: x = x + 1),
      ...>   quote(do: x = x * x),
      ...>   quote(do: x = x - 1),
      ...> ]
      ...> form_original = quote do
      ...>   x = x + 1
      ...>   x = x * x
      ...>   x = x - 1
      ...>   end
      ...> forms_replace = [quote(do: a = a * a), quote(do: a = a + 5)]
      ...> {:ok, {[
      ...>         forms: ^forms_replace,
      ...>         texts: texts,
      ...>         form: ^form_original,
      ...>         result: 63], _schatten}} = forms
      ...> |> produce_schatten(
      ...>   binding: [x: 7],
      ...>   build: [forms:
      ...>     fn _schatten, {:actual,:forms,^forms} ->
      ...>       {:ok, forms_replace}
      ...>     end],
      ...>   expect: [forms: forms_replace],
      ...>   express: [:forms, :texts, :form, :result])
      ...> texts
      ["a = a * a", "a = a + 5"]

  The forms returned by the builder are validated:

      iex> form = quote(do: x = x + 1)
      ...> {:error, error} = form
      ...> |> produce_schatten(
      ...>   build: [forms:
      ...>     fn _schatten, {:actual,:forms,[^form]} ->
      ...>       {:ok, :forms_from_builder_are_invalid}
      ...>     end],
      ...>   expect: [form: form],
      ...>   express: [:forms, :texts])
      ...> error |> Exception.message
      "forms invalid, got: :forms_from_builder_are_invalid"

  The production process is fairly flexible to serve various testing needs.
  In this example a field called *custom* is added (i.e. `:actual`),
  then built and finally expressed together with other fields.

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {[form: ^form, texts: texts, custom: 84], _schatten}} = form
      ...> |> produce_schatten(
      ...>   actual: [custom: 42],
      ...>   build: [custom: fn _, {_verb,_field,value} -> {:ok, value * 2} end],
      ...>   expect: [form: form],
      ...>   express: [:form, :texts, :custom])
      ...> texts
      ["x = x + 1"]

  In the same vein, if an error is expected, it can be caught. Note
  the value of the `:error` key below is the `Exception.message/1`
  text to compare with. If the compare fails the original `{:error,
  error}` is returned. Note the *product* is empty.

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {product, _schatten}} = form
      ...> |> produce_schatten(
      ...>   binding: [x: 7],
      ...>   expect: [result: 42, error: "compare expect actual failed, got: field: :result, expect: 42; actual: 8"])
      ...> product
      []

  This shows the original error being returned when the error does not match:

      iex> form = quote(do: x = x + 1)
      ...> {:error, error} = form
      ...> |> produce_schatten(
      ...>   binding: [x: 7],
      ...>   expect: [result: 42, error: "this will not match"])
      ...> error |> Exception.message
      "compare expect actual failed, got: field: :result, expect: 42; actual: 8"

  Another couple of `:error` examples but this time the value of the `:error` key
  is an arity 1 function that is passed the *error* 3tuple and
  should return a *pattern 0 truthy* value (See
  `Harnais.Form.Utility.truthy0_result/1`). If the normalised truthy
  result is `{:error, error}`, the original `{:error, error}` is returned.

      iex> form = quote(do: x = x + 1)
      ...> {:ok, {product, _schatten}} = form
      ...> |> produce_schatten(
      ...>   binding: [x: 7],
      ...>   expect: [result: 42, error: fn {:actual,:error,_error} -> true end])
      ...> product
      []

      iex> form = quote(do: x = x + 1)
      ...> {:error, error} = form
      ...> |> produce_schatten(
      ...>   binding: [x: 7],
      ...>   expect: [result: 42, error: fn {:actua,:error,_error} -> false end])
      ...> error |> Exception.message
      "compare expect actual failed, got: field: :result, expect: 42; actual: 8"

  The initial forms can be a generator function that is passed the *schatten* and can return
  `form`, `forms`, `{:ok, form}`, `{:ok, forms}`, `{:ok, product}` or `{:error, error}`.

  The `product` must be a `Keyword` and have zero, one of more `:form`
  and/or `:forms` keys: the forms are collected together. Other keys are ignored.

      iex> generator = fn _schatten -> {:ok, quote(do: x = x + 1)} end
      ...> {:ok, {[form: quote(do: x = x + 1), text: text], _schatten}} = generator
      ...> |> produce_schatten(express: [:form, :text])
      ...> text
      "x = x + 1"

      iex> generator = fn _schatten -> {:ok, [
      ...>  form: quote(do: x = x + 1)
      ...>  ]}
      ...> end
      ...> {:ok, {[form: quote(do: x = x + 1), text: text], _schatten}} = generator
      ...> |> produce_schatten(express: [:form, :text])
      ...> text
      "x = x + 1"

      iex> generator = fn _schatten -> {:ok, [
      ...>  form: quote(do: x = x + 1),
      ...>  will_be_ignored: 42,
      ...>  forms: [quote(do: x = x * x), quote(do: x = x - 1)]
      ...>  ]}
      ...> end
      ...> {:ok, {[result: 63, texts: texts], _schatten}} = generator
      ...> |> produce_schatten(binding: [x: 7], express: [:result, :texts])
      ...> texts
      ["x = x + 1", "x = x * x", "x = x - 1"]

  Using a `:error` is useful particularly when the forms generator "wraps"
  another function that can return an error that needs to be caught and compared.

      iex> form_generator = fn _schatten -> {:not, :a, :form} end
      ...> {:ok, {product, _schatten}} = form_generator
      ...> |> produce_schatten(expect: [error: "forms generator function failed, got: form invalid, got: {:not, :a, :form}"])
      ...> product
      []

  The same example but here the `:error` is an arity 1 function that
  is passed the error 3tuple and the return is normalised to a *pattern
  0 truthy result* (See `Harnais.Form.Utility.truthy0_result/1`): A *falsy* result fails the compare.

      iex> form_generator = fn _schatten -> {:not, :a, :form} end
      ...> {:ok, {product, _schatten}} = form_generator
      ...> |> produce_schatten(expect: [
      ...>   error: fn {:actual,:error,error} -> error |> Exception.message |> String.starts_with?("forms generator function failed") end])
      ...> product
      []
  """

  @spec produce_schatten(any, t) :: {:ok, {forms, t}} | {:error, error}
  @spec produce_schatten(any, opts) :: {:ok, {forms, t}} | {:error, error}

  def produce_schatten(form, opts \\ [])

  def produce_schatten(form, %__MODULE__{} = state) do
    with {:ok, %__MODULE__{} = state} <- state |> schatten_update_form(form) do
      state
      |> produce
      |> case do
        {:error, %{__struct__: _} = error} ->
          with {:ok, {_produce, %__MODULE__{}}} = result <- state |> produce_error(error) do
            result
          else
            # if produce_error fails, return the original error
            _ ->
              {:error, error}
          end

        {:ok, {_product, %__MODULE__{}}} = result ->
          result
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  def produce_schatten(schatten, opts) do
    with {:ok, %__MODULE__{} = state} <- opts |> new() do
      schatten |> produce_schatten(state)
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  @harnais_form_schatten_defstruct_updaters @harnais_form_schatten_defstruct
                                            |> Enum.map(fn {field, _} ->
                                              update_fun =
                                                "schatten_update_#{field}" |> String.to_atom()

                                              {:pattern,
                                               [
                                                 pattern: :struct_update,
                                                 name: update_fun,
                                                 field: field,
                                                 doc: false
                                               ]}
                                            end)

  (@harnais_form_schatten_defstruct_updaters ++
     [
       {@plymio_codi_pattern_struct_update,
        [
          args: [:t, :value],
          name: :update_workflow_pipeline,
          field: :workflow_pipeline,
          doc: false
        ]},
       {@plymio_codi_pattern_proxy_fetch,
        [
          :workflow_def_produce,
          :state_base_package,
          :state_defp_update_field_header
        ]}
     ])
  |> CODI.reify_codi(@codi_opts)

  defp update_field(%__MODULE__{} = state, {k, v})
       when k in [
              @harnais_form_schatten_field_eval_binding
            ] do
    with {:ok, v} <- v |> opts_validate do
      {:ok, state |> struct!([{k, v}])}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp update_field(%__MODULE__{} = state, {k, v})
       when k == @harnais_form_schatten_field_form do
    # force the form/forms bootstrapping
    with {:ok, %__MODULE__{} = state} <-
           state
           |> HASWE.state_edit_workflow_pipeline_add_tail(
             {@harnais_form_schatten_workflow_verb_build,
              @harnais_form_schatten_field_bootstrap_form, @harnais_form_schatten_value_not_set}
           ),
         true <- true do
      {:ok, state |> struct!([{k, v}])}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp update_field(%__MODULE__{} = state, {k, v})
       when k in [@harnais_form_schatten_field_transform_opts] do
    with {:ok, transform_opts} <- v |> opts_validate do
      {:ok, state |> struct!([{k, transform_opts}])}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp update_field(%__MODULE__{} = state, {k, v})
       when k in @harnais_form_keys_opts_transform_ast_aliases do
    transform_opts =
      state
      |> Map.get(@harnais_form_schatten_field_transform_opts)
      |> case do
        @harnais_form_schatten_value_transform_opts_initial -> []
        x when is_list(x) -> x
      end
      |> Keyword.put(k, v)

    state |> update_field({@harnais_form_schatten_field_transform_opts, transform_opts})
  end

  defp update_field(%__MODULE__{} = state, {k, v})
       when k in [@harnais_form_schatten_field_workflow_pipeline] do
    with {:ok, pipeline} <- v |> HASWU.validate_workflow_pipeline() do
      {:ok, state |> struct!([{@harnais_form_schatten_field_workflow_pipeline, pipeline}])}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp update_field(
         %__MODULE__{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state,
         {k, v}
       )
       when k in @harnais_form_schatten_workflow_verbs_order do
    pipeline_opts = [{@harnais_form_schatten_key_verb, k}]

    with {:ok, pipeline_new} <- v |> HASWU.normalise_workflow_pipeline(pipeline_opts) do
      pipeline
      |> is_value_set
      |> case do
        true ->
          state |> schatten_update_workflow_pipeline(pipeline ++ pipeline_new)

        _ ->
          state |> schatten_update_workflow_pipeline(pipeline_new)
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp resolve(state)

  defp resolve(%__MODULE__{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state) do
    with {:ok, pipeline} <- pipeline |> HASWU.collate_workflow_pipeline(),
         true <- true do
      pipeline
      |> reduce0_enum(
        [],
        fn {verb, field, args}, pipeline ->
          with {:ok, dependencies} <- {verb, field, args} |> HASWD.dependent_workflow_entry(),
               {:ok, _pipeline} = result <-
                 pipeline
                 |> HASWE.edit_workflow_pipeline([
                   {@harnais_form_schatten_workflow_pipeline_edit_verb_add_head, dependencies},
                   {@harnais_form_schatten_workflow_pipeline_edit_verb_add_tail,
                    {verb, field, args}}
                 ]) do
            result
          else
            {:error, %{__struct__: _}} = result -> result
          end
        end
      )
      |> case do
        {:error, %{__exception__: true}} = result ->
          result

        {:ok, pipeline} ->
          with {:ok, pipeline} <- pipeline |> HASWU.collate_workflow_pipeline(),
               {:ok, %__MODULE__{}} = result <-
                 state |> schatten_update_workflow_pipeline(pipeline) do
            result
          else
            {:error, %{__exception__: true}} = result -> result
          end
      end
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp build(state)

  defp build(%__MODULE__{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state)
       when is_list(pipeline) and length(pipeline) == 0 do
    {:ok, state}
  end

  defp build(%__MODULE__{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state) do
    with {:ok, pipeline} <- pipeline |> HASWU.collate_workflow_pipeline(),
         {:ok, %__MODULE__{} = state} <- state |> schatten_update_workflow_pipeline(pipeline) do
      pipeline
      |> reduce2_enum(
        state,
        fn {verb, field, args}, state ->
          state |> HASWR.run_workflow_pipeline_tuple({verb, field, args})
        end
      )
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp express(state)

  defp express(%__MODULE__{} = state) do
    with {:ok, %__MODULE__{} = state} <- state |> resolve,
         {:ok, %__MODULE__{} = state} <- state |> build,
         {:ok, pipeline} <- state |> Map.fetch(@harnais_form_schatten_field_workflow_pipeline),
         {:ok, pipeline} <-
           pipeline
           |> HASWF.filter_workflow_pipeline_by_verb(@harnais_form_schatten_workflow_verb_produce) do
      product =
        pipeline
        |> Enum.map(&Tuple.delete_at(&1, 0))

      {:ok, {product, state}}
    else
      {:error, %{__exception__: true}} = result -> result
    end
  end

  defp produce_error(schatten, error)

  defp produce_error(
         %__MODULE__{@harnais_form_schatten_field_workflow_pipeline => pipeline} = state,
         error
       )
       when is_filled_list(pipeline) do
    pipeline = state |> Map.get(@harnais_form_schatten_field_workflow_pipeline)

    # check if there is there are error tuples
    with {:ok, error_pipeline} <-
           pipeline
           |> HASWF.filter_workflow_pipeline_by_field(@harnais_form_schatten_field_error) do
      error_pipeline
      |> length
      |> case do
        0 ->
          {:error, error}

        _ ->
          with {:ok, %__MODULE__{} = state} <- state |> update_workflow_pipeline(error_pipeline),
               {:ok, %__MODULE__{} = state} <-
                 state
                 |> HASWE.state_edit_workflow_pipeline_add_tail(
                   {@harnais_form_schatten_workflow_verb_actual,
                    @harnais_form_schatten_field_error, error}
                 ),
               {:ok, {_product, %__MODULE__{}}} = result <- state |> produce do
            result
          else
            {:error, %{__exception__: true}} = result -> result
          end
      end
    else
      {:error, %{__struct__: _}} = result -> result
    end
  end

  defp produce_error(%__MODULE__{} = state, _error) do
    new_error_result(m: "workflow pipeline empty", v: state)
  end
end
