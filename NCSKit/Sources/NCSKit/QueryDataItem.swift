


public struct QueryDataItem<AttributesType : Codable> : Codable {
  public let id : String
  public let type : String
  public let attributes : AttributesType
}
