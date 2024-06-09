import gleam/io
import jackson/internal/parser

pub fn main() {
  "{\"hello\": [1,2,3,4,4.67,true, false, null, {\"henlo\": \"noway \\u1234 \"}]}"
  |> parser.parse
  |> io.debug
  // int.parse("+23")
  // |> io.debug
}
