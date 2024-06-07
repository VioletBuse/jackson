import gleam/float
import gleam/int
import gleam/regex
import gleam/result
import gleam/string

pub type Token {
  OpenCurly
  CloseCurly
  OpenSquare
  CloseSquare
  IntLiteral(Int)
  FloatLiteral(Float)
  StringLiteral(String)
  TrueLiteral
  FalseLiteral
  NullLiteral
  Colon
  Comma
}

pub type TokenizationError {
  Unexpected(String)
  Ended
}

pub fn tokenize(input: String) -> Result(List(Token), TokenizationError) {
  tokenize_loop(input)
}

fn tokenize_loop(input: String) -> Result(List(Token), TokenizationError) {
  let processed = string.trim(input)
  case processed {
    "" -> Ok([])
    ":" <> rest -> continue_loop(Colon, rest)
    "," <> rest -> continue_loop(Comma, rest)
    "{" <> rest -> continue_loop(OpenCurly, rest)
    "}" <> rest -> continue_loop(CloseCurly, rest)
    "[" <> rest -> continue_loop(OpenSquare, rest)
    "]" <> rest -> continue_loop(CloseSquare, rest)
    "true" <> rest -> continue_loop(TrueLiteral, rest)
    "false" <> rest -> continue_loop(FalseLiteral, rest)
    "null" <> rest -> continue_loop(NullLiteral, rest)
    "\"" <> _ ->
      case try_tokenize_string(processed) {
        Ok(#(token, rest)) -> continue_loop(token, rest)
        Error(err) -> Error(err)
      }
    "0" <> _
    | "1" <> _
    | "2" <> _
    | "3" <> _
    | "4" <> _
    | "5" <> _
    | "6" <> _
    | "7" <> _
    | "8" <> _
    | "9" <> _
    | "." <> _ ->
      case try_tokenize_number(processed) {
        Ok(#(token, rest)) -> continue_loop(token, rest)
        Error(err) -> Error(err)
      }
    _ -> Error(Unexpected(processed))
  }
}

fn continue_loop(
  token: Token,
  rest: String,
) -> Result(List(Token), TokenizationError) {
  use remainder <- result.try(tokenize_loop(rest))
  Ok([token, ..remainder])
}

fn try_tokenize_string(
  input: String,
) -> Result(#(Token, String), TokenizationError) {
  let regex_str = "\"(([^\\0-\\x19\"\\\\]|\\\\[^\\0-\\x19])*)\""
  let assert Ok(re) = regex.from_string(regex_str)

  let scan_res = case regex.scan(with: re, content: input) {
    [regex.Match(..) as match, ..] -> Ok(match)
    _ -> Error(Unexpected(input))
  }

  use regex.Match(content, ..) <- result.try(scan_res)

  let remainder =
    string.slice(input, string.length(content), string.length(input))
  let string_content = string.slice(content, 1, string.length(content) - 2)

  Ok(#(StringLiteral(string_content), remainder))
}

fn try_tokenize_number(
  input: String,
) -> Result(#(Token, String), TokenizationError) {
  let assert Ok(re) = regex.from_string("[0-9_]*\\.?[0-9_]+")
  let scan_res = case regex.scan(with: re, content: input) {
    [regex.Match(..) as match, ..] -> Ok(match)
    _ -> Error(Unexpected(input))
  }

  use regex.Match(content, ..) <- result.try(scan_res)

  let remainder =
    string.slice(input, string.length(content), string.length(input))
  let filtered = string.replace(content, "_", "")

  case int.parse(filtered), float.parse(filtered) {
    Ok(int), _ -> Ok(#(IntLiteral(int), remainder))
    _, Ok(float) -> Ok(#(FloatLiteral(float), remainder))
    _, _ -> Error(Unexpected(input))
  }
}
