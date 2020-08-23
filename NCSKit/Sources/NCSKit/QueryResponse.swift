


public struct QueryResponse<AttributesType : Codable> : Codable {
  public let data : Many<QueryDataItem<AttributesType>>
  public let meta : QueryResponseMetadata?
}
