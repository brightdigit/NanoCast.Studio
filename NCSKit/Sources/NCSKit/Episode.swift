import Foundation

public struct Episode : Identifiable {
  public let id : Int
  public let number : Int?
  public let mediaURL : URL
  public let title : String
  public let summary : String?
  public let status: EpisodeStatus
}
