import Foundation

public struct UserAttributes : Codable {
  public let name : String
}

public struct ShowAttributes : Codable {
  public let title : String
}

public struct EpisodeAttributes : Codable {
  public let number : Int
  public let media_url : URL
  public let title : String
  public let summary : String
}

public enum EpisodeStatus : String, Codable {
  case published
  case scheduled
  case draft
}
