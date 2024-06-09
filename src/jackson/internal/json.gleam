pub type Json {
  Object(List(#(String, Json)))
  Array(List(Json))
  Integer(Int)
  Float(Float)
  Null
  Bool(Bool)
  String(String)
}
