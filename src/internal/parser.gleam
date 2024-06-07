import gleam/dict.{type Dict}
import gleam/list
import gleam/result
import internal/tokenizer.{
  type Token, CloseCurly, CloseSquare, Colon, Comma, FalseLiteral, FloatLiteral,
  IntLiteral, NullLiteral, OpenCurly, OpenSquare, StringLiteral, TrueLiteral,
}

pub type ParseError {
  UnexpectedToken(Token)
  EndedEarly
}

pub type JsonValue {
  NumInt(Int)
  NumFloat(Float)
  Str(String)
  Boolean(Bool)
  Null
  Array(List(JsonValue))
  Object(List(#(String, JsonValue)))
}

pub fn parse(tokens: List(Token)) -> Result(JsonValue, ParseError) {
  use #(value, rest) <- result.try(internal_parse(tokens))

  case rest {
    [] -> Ok(value)
    [first, ..] -> Error(UnexpectedToken(first))
  }
}

fn internal_parse(
  tokens: List(Token),
) -> Result(#(JsonValue, List(Token)), ParseError) {
  case tokens {
    [] -> Error(EndedEarly)
    [OpenCurly, ..] -> parse_object(tokens)
    [OpenSquare, ..] -> parse_array(tokens)
    [NullLiteral, ..rest] -> Ok(#(Null, rest))
    [StringLiteral(val), ..rest] -> Ok(#(Str(val), rest))
    [FloatLiteral(val), ..rest] -> Ok(#(NumFloat(val), rest))
    [IntLiteral(val), ..rest] -> Ok(#(NumInt(val), rest))
    [TrueLiteral, ..rest] -> Ok(#(Boolean(True), rest))
    [FalseLiteral, ..rest] -> Ok(#(Boolean(False), rest))
    [next, ..] -> Error(UnexpectedToken(next))
  }
}

fn parse_object(
  tokens: List(Token),
) -> Result(#(JsonValue, List(Token)), ParseError) {
  case tokens {
    [OpenCurly, ..rest] ->
      case parse_object_interior(rest) {
        Ok(#(entries, remainder)) -> Ok(#(Object(entries), remainder))
        Error(inner) -> Error(inner)
      }
    [] -> Error(EndedEarly)
    [first, ..] -> Error(UnexpectedToken(first))
  }
}

fn parse_object_interior(
  tokens: List(Token),
) -> Result(#(List(#(String, JsonValue)), List(Token)), ParseError) {
  case tokens {
    [CloseCurly, ..rest] -> Ok(#([], rest))
    [StringLiteral(key), Colon, ..rest] ->
      case internal_parse(rest) {
        Ok(#(value, [CloseCurly, ..rest])) -> Ok(#([#(key, value)], rest))
        Ok(#(value, [Comma, ..rest])) -> {
          use #(next_entries, final_rest) <- result.try(parse_object_interior(
            rest,
          ))
          Ok(#([#(key, value), ..next_entries], final_rest))
        }
        Ok(#(_, [])) -> Error(EndedEarly)
        Ok(#(_, [first, ..])) -> Error(UnexpectedToken(first))
        Error(inner) -> Error(inner)
      }
    [first, ..] -> Error(UnexpectedToken(first))
    [] -> Error(EndedEarly)
  }
}

fn parse_array(
  tokens: List(Token),
) -> Result(#(JsonValue, List(Token)), ParseError) {
  case tokens {
    [OpenSquare, ..rest] ->
      case parse_array_interior(rest) {
        Ok(#(values, remainder)) -> Ok(#(Array(values), remainder))
        Error(val) -> Error(val)
      }
    [] -> Error(EndedEarly)
    [first, ..] -> Error(UnexpectedToken(first))
  }
}

fn parse_array_interior(
  tokens: List(Token),
) -> Result(#(List(JsonValue), List(Token)), ParseError) {
  case internal_parse(tokens) {
    Ok(#(next_val, [CloseSquare, ..rest])) -> Ok(#([next_val], rest))
    Ok(#(next_val, [Comma, ..rest])) -> {
      use #(next_list, rest_result) <- result.try(parse_array_interior(rest))
      Ok(#([next_val, ..next_list], rest_result))
    }
    Ok(#(_, [next_token, ..])) -> Error(UnexpectedToken(next_token))
    Ok(#(_, [])) -> Error(EndedEarly)
    Error(inner) -> Error(inner)
  }
}
