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

/// take a dynamic value, created either manually or from the `jackson.decode` function,
/// and turn it back into json. This is how the following values are converted:
///
///   - Int -> json.Int(inner)
///   - Float -> json.Float(inner)
///   - String -> json.String(inner)
///   - Bool -> json.Bool(inner)
///   - Nil -> json.Null
///   - List(#(String, Json)) -> json.Object(entries)
///   - List(Json) -> json.Array(entries)
///
/// A slight problem is that gleam's `dynamic.tuple2` is unable to differentiate between
/// a tuple and an array of length two. Additionally, if your json contains an array, whose
/// children are all arrays of length two where the value at index 0 is a string,
/// (such as `[["a", 1], ["b", 2], ["c", 3], ["d", 4]]`) then this function will re-encode it
/// as though it were the following object:
///
/// ```json
/// {
///   "a": 1,
///   "b": 2,
///   "c": 3,
///   "d": 4
/// }
/// ```
pub fn dynamic_to_json(dyn: Dynamic) -> Result(Json, DecodeErrors) {
  encoder.dynamic_to_json(dyn)
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
