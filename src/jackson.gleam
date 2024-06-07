import gleam/io
import gleam/result
import internal/parser
import internal/tokenizer

pub type Error {
  TokenizingError(tokenizer.TokenizationError)
  ParsingError(parser.ParseError)
}

fn str_to_token(input: String) -> Result(List(tokenizer.Token), Error) {
  tokenizer.tokenize(input) |> result.map_error(TokenizingError)
}

fn tokens_to_json(
  tokens: List(tokenizer.Token),
) -> Result(parser.JsonValue, Error) {
  parser.parse(tokens) |> result.map_error(ParsingError)
}

pub fn parse_json(input: String) -> Result(parser.JsonValue, Error) {
  str_to_token(input)
  |> result.try(tokens_to_json)
}

pub fn main() {
  "{\"hello\": \"world\", \"array\": [1,2,4.5,null,true, {\"one\":\"value-1\", \"two\": [34, \"string value\"]}]}"
  |> parse_json
  |> io.debug
}
