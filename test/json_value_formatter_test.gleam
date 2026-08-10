import birdie
import glance
import gleam/json
import gleam/string
import gleeunit
import json_value
import json_value_formatter
import simplifile

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn pretty_json_null_test() {
  json_value.null
  |> json_value_formatter.to_pretty_json_string()
  |> birdie.snap("pretty_json_null")
}

pub fn pretty_json_string_test() {
  json_value.string("hello \"world")
  |> json_value_formatter.to_pretty_json_string()
  |> birdie.snap("pretty_json_string")
}

pub fn gleam_escape_test() {
  let input = "\\\"\n\r\tHello, world!"
  let expected = "\"\\\\\\\"\\n\\r\\tHello, world!\""

  assert json_value_formatter.gleam_escape(input) == expected
}

pub fn pretty_json_empty_object_test() {
  json_value.object([])
  |> json_value_formatter.to_pretty_json_string()
  |> birdie.snap("pretty_json_empty_object")
}

pub fn pretty_json_object_test() {
  json_value.object([
    #("wibble", json_value.string("wobble")),
    #("foo", json_value.string("bar")),

    #("empty", json_value.object([])),
    #(
      "tags",
      json_value.array(
        [
          "hello",
          "hello",
          "hello",
          "hello",
        ],
        json_value.string,
      ),
    ),
    #(
      "times",
      json_value.array(
        [
          1,
          2,
          4,
          5,
          6,
          7,
          8,
          9,
        ],
        json_value.int,
      ),
    ),
    #(
      "bar",
      json_value.object([
        #("1", json_value.string("3")),
        #("2", json_value.string("4")),
      ]),
    ),

    #(
      "key",
      json_value.Array([
        json_value.object([
          #("wibble", json_value.string("wobble")),
          #(
            "some_numbers",
            json_value.array(
              [
                1,
                2,
                4,
                5,
                6,
                7,
                8,
                9,
              ],
              json_value.int,
            ),
          ),
        ]),
      ]),
    ),
    #(
      "key2",
      json_value.Array([
        json_value.null,
        json_value.object([
          #("wibble", json_value.string("wobble")),
          #(
            "some_numbers",
            json_value.array(
              [
                1,
                2,
                4,
                5,
                6,
                7,
                8,
                9,
              ],
              json_value.int,
            ),
          ),
        ]),
      ]),
    ),
  ])
  |> json_value_formatter.to_pretty_json_string()
  |> birdie.snap("pretty_json_complex_object")
}

pub fn pretty_json_complex_test() {
  let name = "complex"
  let assert Ok(data) = simplifile.read("test/fixtures/" <> name <> ".json")
  let assert Ok(json) = json.parse(data, json_value.decoder())
  json_value_formatter.to_pretty_json_string(json)
  |> birdie.snap("pretty_json_" <> name)
}

pub fn to_json_complex_test() {
  let name = "complex"
  let assert Ok(data) = simplifile.read("test/fixtures/" <> name <> ".json")
  let assert Ok(json) = json.parse(data, json_value.decoder())
  let code = json_value_formatter.to_json_code(json)

  assert_valid_gleam(code)

  code
  |> birdie.snap("to_json_" <> name)
}

pub fn to_json_value_complex_test() {
  let name = "complex"
  let assert Ok(data) = simplifile.read("test/fixtures/" <> name <> ".json")
  let assert Ok(json) = json.parse(data, json_value.decoder())
  let code = json_value_formatter.to_json_value_code(json)

  assert_valid_gleam(code)

  code
  |> birdie.snap("to_json_value_" <> name)
}

pub fn assert_valid_gleam(code: String) {
  let assert Ok(_) =
    code
    |> wrap_in_function("main", _)
    |> glance.module()
    as code

  Nil
}

fn wrap_in_function(name, code) {
  "fn $name(){ $code }"
  |> string.replace("$name", name)
  |> string.replace("$code", code)
}
