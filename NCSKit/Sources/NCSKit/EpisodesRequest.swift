
public struct ListEpisodesRequest : Request {
  
  public static var method: RequestMethod  = .get
  
  public let showId : String
  public init (showId : String) {
    self.showId = showId
  }
  public var parameters: [String : Any]? {
    ["show_id" : self.showId]
  }
  public let data: [String : Any]? = nil
  public let path = "episodes"
  
  public typealias AttributesType = EpisodeAttributes
}
