import glam/doc.{type Document}
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import json_value

pub fn pretty_json_string(json_value: json_value.JsonValue) {
  do_pretty_json_string(json_value, 0)
  |> doc.to_string(50)
}

fn do_pretty_json_string(
  json_value: json_value.JsonValue,
  depth: Int,
) -> doc.Document {
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

fn quoted_string(input: String) {
  doc.from_string("\"" <> input <> "\"")
}
