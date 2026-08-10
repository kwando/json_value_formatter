import glam/doc.{type Document}
import gleam/bool
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/string
import json_value.{type JsonValue}

/// Renders a JSON value as formatted JSON with a line width of 80 characters.
pub fn to_pretty_json_string(json_value: JsonValue) -> String {
  do_pretty_json_string(json_value, 0)
  |> doc.to_string(80)
}

fn do_pretty_json_string(json_value: JsonValue, depth: Int) -> doc.Document {
  case json_value {
    json_value.Null -> doc.from_string("null")
    json_value.String(value) -> quoted_string(value)
    json_value.Int(value) -> int.to_string(value) |> doc.from_string
    json_value.Bool(value) ->
      case value {
        True -> "true"
        False -> "false"
      }
      |> doc.from_string
    json_value.Float(value) -> float.to_string(value) |> doc.from_string
    json_value.Array(values) -> {
      case values {
        [] -> doc.from_string("[]")
        values -> {
          list.map(values, do_pretty_json_string(_, depth + 1))
          |> doc.concat_join([doc.from_string(","), doc.space])
          |> doc.prepend_docs([doc.from_string("["), doc.space])
          |> doc.nest(2)
          |> doc.append_docs([doc.space, doc.from_string("]")])
          |> doc.group
        }
      }
    }
    json_value.Object(values) -> {
      case dict.to_list(values) {
        [] -> doc.from_string("{}")
        values -> {
          list.map(values, fn(value) {
            let #(name, value) = value
            field(name, do_pretty_json_string(value, depth + 1))
          })
          |> doc.concat_join([doc.from_string(","), doc.space])
          |> doc.prepend_docs([doc.from_string("{"), doc.space])
          |> doc.nest(2)
          |> doc.append_docs([doc.space, doc.from_string("}")])
          |> doc.group
        }
      }
    }
  }
}

fn field(name: String, value_doc: Document) -> Document {
  doc.concat([quoted_string(name), doc.from_string(": "), value_doc])
  |> doc.group
}

fn quoted_string(input: String) -> Document {
  doc.from_string("\"" <> input <> "\"")
}

const json_names = FunctionNames(
  null: "json.null",
  string: "json.string",
  int: "json.int",
  float: "json.float",
  preprocessed_array: "json.preprocessed_array",
  array: "json.array",
  object: "json.object",
  bool: "json.bool",
)

const json_value_names = FunctionNames(
  null: "json_value.null",
  string: "json_value.string",
  int: "json_value.int",
  float: "json_value.float",
  preprocessed_array: "json_value.preprocessed_array",
  array: "json_value.array",
  object: "json_value.object",
  bool: "json_value.bool",
)

/// Generates formatted Gleam source that reconstructs a JSON value with `gleam/json`.
pub fn to_json_code(json_value: JsonValue) -> String {
  do_to_json(json_value, json_names)
  |> doc.to_string(120)
}

/// Generates formatted Gleam source that reconstructs a JSON value with `json_value`.
pub fn to_json_value_code(json_value: JsonValue) -> String {
  do_to_json(json_value, json_value_names)
  |> doc.to_string(120)
}

type FunctionNames {
  FunctionNames(
    null: String,
    string: String,
    int: String,
    float: String,
    preprocessed_array: String,
    array: String,
    object: String,
    bool: String,
  )
}

fn do_to_json(
  json_value: JsonValue,
  function_names: FunctionNames,
) -> Document {
  case json_value {
    json_value.Null -> doc.from_string(function_names.null <> "()")
    json_value.String(value) ->
      call_doc(function_names.string, [quoted_string(value)])
    json_value.Int(value) ->
      call_doc(
        function_names.int,
        int.to_string(value) |> doc.from_string |> list.wrap,
      )
    json_value.Bool(value) ->
      call_doc(
        function_names.bool,
        bool.to_string(value) |> doc.from_string |> list.wrap,
      )
    json_value.Float(value) ->
      call_doc(
        function_names.float,
        float.to_string(value) |> doc.from_string |> list.wrap,
      )
    json_value.Array(values) -> {
      case classify_array(values) {
        Empty -> doc.from_string(function_names.preprocessed_array <> "([])")
        PreprocessedArray ->
          list.map(values, do_to_json(_, function_names))
          |> doc.concat_join([doc.from_string(","), doc.space])
          |> doc.prepend_docs([
            doc.from_string(function_names.preprocessed_array <> "(["),
            doc.soft_break,
          ])
          |> doc.nest(2)
          |> doc.append_docs([doc.soft_break, doc.from_string("])")])
          |> doc.group
        Array(literals:, kind:) ->
          list.map(literals, doc.from_string)
          |> doc.concat_join([doc.from_string(","), doc.space])
          |> doc.prepend_docs([
            doc.from_string(function_names.array <> "(["),
            doc.soft_break,
          ])
          |> doc.nest(2)
          |> doc.append_docs([
            doc.space,
            doc.from_string("], "),
            doc.from_string(kind),
            doc.from_string(")"),
          ])
          |> doc.group
      }
    }
    json_value.Object(values) -> {
      let field = fn(field) {
        let #(name, value) = field
        doc.concat_join(
          [
            quoted_string(name),
            do_to_json(value, function_names),
          ],
          [doc.from_string(","), doc.space],
        )
        |> parenthesise("#(", ")")
      }
      values
      |> dict.to_list
      |> list.map(field)
      |> doc.concat_join([doc.from_string(","), doc.space])
      |> doc.prepend_docs([
        doc.from_string(function_names.object <> "(["),
        doc.soft_break,
      ])
      |> doc.nest(2)
      |> doc.append_docs([doc.soft_break, doc.from_string("])")])
      |> doc.group
    }
  }
}

fn call_doc(function_name: String, args: List(Document)) -> Document {
  doc.concat([
    doc.from_string(function_name),
    parenthesise(doc.join(args, doc.from_string(",")), "(", ")"),
  ])
}

type ArrayClass {
  Empty
  PreprocessedArray
  Array(literals: List(String), kind: String)
}

fn classify_array(values: List(JsonValue)) -> ArrayClass {
  case values {
    [] -> Empty
    [value, ..values] ->
      case gleam_literal(value) {
        Error(_) -> PreprocessedArray
        Ok(#(literal, kind)) -> classify_array_loop(values, kind, [literal])
      }
  }
}

fn gleam_literal(value: JsonValue) -> Result(#(String, String), Nil) {
  case value {
    json_value.Null -> Error(Nil)
    json_value.String(value) -> Ok(#(gleam_escape(value), "json.string"))
    json_value.Int(value) -> Ok(#(int.to_string(value), "json.int"))
    json_value.Bool(value) -> Ok(#(bool.to_string(value), "json.bool"))
    json_value.Float(value) -> Ok(#(float.to_string(value), "json.float"))
    json_value.Array(_) -> Error(Nil)
    json_value.Object(_) -> Error(Nil)
  }
}

fn classify_array_loop(
  values: List(JsonValue),
  expected: String,
  literals: List(String),
) -> ArrayClass {
  case values {
    [] -> Array(list.reverse(literals), expected)
    [value, ..values] -> {
      case gleam_literal(value) {
        Ok(#(literal, kind)) if kind == expected ->
          classify_array_loop(values, kind, [literal, ..literals])
        Error(_) | Ok(_) -> PreprocessedArray
      }
    }
  }
}

/// Escapes a string as a quoted Gleam string literal.
@internal
pub fn gleam_escape(input: String) -> String {
  "\""
  <> input
  |> string.replace("\\", "\\\\")
  |> string.replace("\"", "\\\"")
  |> string.replace("\n", "\\n")
  |> string.replace("\r", "\\r")
  |> string.replace("\t", "\\t")
  <> "\""
}

fn parenthesise(document: Document, open: String, close: String) -> Document {
  document
  |> doc.prepend_docs([doc.from_string(open), doc.soft_break])
  |> doc.nest(by: 2)
  |> doc.append_docs([doc.soft_break, doc.from_string(close)])
  |> doc.group
}
