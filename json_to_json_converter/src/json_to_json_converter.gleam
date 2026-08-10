import gleam/dynamic/decode
import gleam/json
import gleam/result
import json_value
import json_value_formatter
import lustre
import lustre/attribute.{class}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.application(init:, update:, view:)

  lustre.start(app, "#app", [])
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserUpdatedInput(input) -> {
      let model =
        model
        |> update_input(input)
        |> store_input

      #(model, enable_tabs_for_textare("input"))
    }

    UserClickedFormatJson -> {
      case format_json(model.input) {
        Ok(formatted_json) -> {
          let model =
            Model(..model, input: formatted_json)
            |> store_input

          #(model, effect.none())
        }
        Error(_) -> #(model, effect.none())
      }
    }
    UserClickedCopyToClipboard -> {
      copy_text_to_clipboard(model.output)
      |> echo
      #(model, effect.none())
    }
  }
}

@external(javascript, "./json_to_json_converter.ffi.mjs", "formatJson")
fn format_json(input: String) -> Result(String, Nil)

@external(javascript, "./json_to_json_converter.ffi.mjs", "setSessionStorage")
fn set_session_storage(key: String, value: String) -> Nil

@external(javascript, "./json_to_json_converter.ffi.mjs", "getSessionStorage")
fn get_session_storage(key: String) -> Result(String, Nil)

@external(javascript, "./json_to_json_converter.ffi.mjs", "copyTextToClipboard")
fn copy_text_to_clipboard(text: String) -> Nil

@external(javascript, "./json_to_json_converter.ffi.mjs", "enableTab")
fn enable_tabs(id: String) -> Nil

fn enable_tabs_for_textare(id: String) {
  effect.after_paint(fn(_, _) {
    enable_tabs(id)
    Nil
  })
}

fn store_input(model: Model) -> Model {
  set_session_storage("input", model.input)
  model
}

fn update_input(model: Model, input: String) -> Model {
  let valid_json = json.parse(input, decode.dynamic) |> result.is_ok
  let model = Model(..model, input:, valid_json:)

  case json.parse(input, json_value.decoder()) {
    Ok(json_value) -> {
      Model(..model, output: json_value_formatter.to_json_code(json_value))
    }
    Error(_) -> Model(..model, output: "")
  }
}

pub type Msg {
  UserUpdatedInput(String)
  UserClickedFormatJson
  UserClickedCopyToClipboard
}

pub type Model {
  Model(input: String, output: String, valid_json: Bool)
}

fn init(_list: List(a)) -> #(Model, Effect(Msg)) {
  let input = get_session_storage("input") |> result.unwrap("")
  let model =
    Model(input: "", output: "", valid_json: False)
    |> update_input(input)

  #(model, effect.none())
}

fn view(model: Model) -> Element(Msg) {
  html.div([class("flex w-full h-full")], [
    html.div(
      [
        class(
          "w-full flex flex-col gap-4 min-h-full border-r left p-4 text-cyan-950",
        ),
      ],
      [
        html.textarea(
          [
            class("w-full grow-1 font-mono text-sm"),
            attribute.autofocus(True),
            attribute.placeholder("Write some JSON here"),
            event.on_input(UserUpdatedInput),
            attribute.spellcheck(False),
            attribute.autocapitalize("none"),
            attribute.autocorrect(False),
            attribute.id("input"),
          ],
          model.input,
        ),
        html.button(
          [
            class("btn m-4"),
            attribute.disabled(!model.valid_json),
            event.on_click(UserClickedFormatJson),
          ],
          [
            html.text("Format JSON"),
          ],
        ),
      ],
    ),
    html.div([class("w-full p-4 overflow-scroll relative right")], [
      html.button(
        [
          class("btn m-4 absolute right-2"),
          attribute.disabled(!model.valid_json),
          event.on_click(UserClickedCopyToClipboard),
        ],
        [
          html.text("Copy to Clipboard"),
        ],
      ),
      html.div(
        [
          class("absolute bg-red-500 text-white p-4"),
          attribute.classes([#("hidden", model.valid_json || model.input == "")]),
        ],
        [
          html.text("The JSON on the left is invalid"),
        ],
      ),
      html.pre([class("h-full text-sm")], [html.text(model.output)]),
    ]),
  ])
}
