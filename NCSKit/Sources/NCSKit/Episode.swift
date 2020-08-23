import Foundation

public struct Episode {
  public let id : Int
  public let number : Int?
  public let media_url : URL
  public let title : String
  public let summary : String?
  public let status: EpisodeStatus
}
