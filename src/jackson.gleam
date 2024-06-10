import gleam/dynamic.{type DecodeErrors, type Dynamic}
import gleam/string_builder
import jackson/internal/decoder
import jackson/internal/encoder
import jackson/internal/json.{type Json}
import jackson/internal/parser
import jackson/internal/resolver

/// build a json string value
pub fn string(value: String) {
  json.String(value)
}

/// build a json number value
pub fn int(value: Int) {
  json.Integer(value)
}

/// build a json float value
pub fn float(value: Float) {
  json.Float(value)
}

/// build a json null value
pub fn null() {
  json.Null
}

/// build a json boolean value
pub fn bool(value: Bool) {
  json.Bool(value)
}

/// build an array from a list of json values
pub fn array(entries: List(Json)) {
  json.Array(entries)
}

/// build a json object from a list of keys and values, similar to `dict.from_list`
pub fn object(entries: List(#(String, Json))) {
  json.Object(entries)
}

/// parse a string into json
pub fn parse(in: String) -> Result(Json, String) {
  parser.parse(in)
}

/// take a parsed json value from `jackson.parse` and decode it from a dynamic
pub fn decode(
  json: Json,
  decoder: fn(Dynamic) -> Result(a, DecodeErrors),
) -> Result(a, DecodeErrors) {
  decoder.decode(json, decoder)
}

/// encode json to string (uses `jackson.to_string_builder` under the hood)
pub fn to_string(json: Json) -> String {
  encoder.to_string(json)
}

/// encode json to a string builder
pub fn to_string_builder(json: Json) -> string_builder.StringBuilder {
  encoder.to_string_builder(json)
}

/// resolve a json pointer, starting with a "/" or a "#/"
/// *note* json pointers starting with a "#/" will be resolved with reference to the
/// current json value, and not a remote resource
pub fn resolve_pointer(json: Json, pointer: String) {
  resolver.resolve(json, pointer)
}
