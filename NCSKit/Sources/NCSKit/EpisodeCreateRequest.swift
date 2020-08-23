


public struct EpisodeCreateRequest : Request {
  
  
  public typealias AttributesType = EpisodeAttributes
  public static let path: String = "episodes"
  public static var method: RequestMethod = .post
  public let episode : EpisodeCreate
  
  public let parameters: [String : Any]? = nil
  
  public var data: [String : Any]? {
    return self.episode.parameters
  }
  
  public init (episode: EpisodeCreate) {
    self.episode = episode
  }
}
