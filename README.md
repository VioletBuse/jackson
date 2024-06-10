# jackson

[![Package Version](https://img.shields.io/hexpm/v/jackson)](https://hex.pm/packages/jackson)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/jackson/)

```sh
gleam add jackson
```

## Decoding a json value

```gleam
import jackson
import gleam/result
import gleam/dynamic

pub fn main() {
  fetch_value()
  |> jackson.parse
  |> result.map(
    jackson.decode(dynamic.decode2(Constructor, field("id", dynamic.int), field("name", dynamic.string))
  )
}
```

## Encoding a json value

```gleam
import jackson

jackson.object(
  #("id", jackson.int(2)),
  #("name", jackson.string("michael"))
)
|> jackson.to_string()
// {"id": 2, "name": "michael"}
```

Further documentation can be found at <https://hexdocs.pm/jackson>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```
