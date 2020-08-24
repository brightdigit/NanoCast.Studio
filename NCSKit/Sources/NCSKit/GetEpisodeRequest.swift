
public struct GetEpisodeRequest : Request {
  
  public static var method: RequestMethod  = .get
  
  public let episodeId : String
  public init (episodeId : String) {
    self.episodeId = episodeId
  }
  public let parameters: [String : Any]? = nil
  public let data: [String : Any]? = nil
  public var path: String {
    "episodes/\(self.episodeId)"
  }
  
  public typealias AttributesType = EpisodeAttributes
}
