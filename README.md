# json_value_formatter

[![Package Version](https://img.shields.io/hexpm/v/json_value_formatter)](https://hex.pm/packages/json_value_formatter)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://json-value-formatter.hexdocs.pm/)

```sh
gleam add json_value_formatter@1
```

Format `json_value` values as JSON or generate Gleam source that recreates them.

## Usage

```gleam
import json_value
import json_value_formatter

pub fn main() -> Nil {
  let value = json_value.object([
    #("name", json_value.string("Ada")),
    #("scores", json_value.array([10, 20], json_value.int)),
  ])

  let json = json_value_formatter.to_pretty_json_string(value)
  let json_code = json_value_formatter.to_json_code(value)
  let json_value_code = json_value_formatter.to_json_value_code(value)
}
```

`to_json_code` produces source using `gleam/json` and `to_json_value_code` produces
source using `json_value`.

API documentation is available at <https://json-value-formatter.hexdocs.pm/>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```
