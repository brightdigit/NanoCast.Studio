import Foundation

public struct EpisodeCreate {
  public init(show_id: Int, season : Int = 1, number: Int? = nil,  audio_url: URL? = nil, title: String? = nil, summary: String? = nil, status: EpisodeStatus = .draft) {
    self.number = number
    self.audio_url = audio_url
    self.title = title
    self.summary = summary
    self.show_id = show_id
    self.season = season
    self.status = status
  }
  
  public let show_id : Int
  public let number : Int?
  public let audio_url : URL?
  public let title : String?
  public let summary : String?
  public let season : Int
  public let status : EpisodeStatus
  
  var parameters : [String : Any] {
    var parameters = [String : Any]()
    
    var episode = [String : Any]()
    episode.forKey("season", compactSet: season)
    episode.forKey("number", compactSet: number)
    episode.forKey("audio_url", compactSet: audio_url)
    episode.forKey("title", compactSet: title)
    episode.forKey("summary", compactSet: summary)
    episode.forKey("show_id", compactSet: show_id)
    
    parameters["episode"] = episode
    return parameters
  }
  
}
