import gleam/io
import gleam/result
import gleam/string_builder
import jackson/internal/encoder
import jackson/internal/parser

pub fn main() {
  "{\"hello\": [1,2,3,4,4.67,true, false, null, {\"henlo\": \"noway \n \"}]}"
  |> parser.parse
  |> result.map(encoder.to_string_builder)
  |> result.map(string_builder.to_string)
  |> result.map(io.println)
  // int.parse("+23")
  // |> io.debug
}
