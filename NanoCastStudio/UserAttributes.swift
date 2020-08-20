import Foundation

struct UserAttributes : Codable {
  let name : String
}

struct ShowAttributes : Codable {
  let title : String
}

struct EpisodeAttributes : Codable {
  let number : Int
  let media_url : URL
  let title : String
  let summary : String
}

enum EpisodeStatus : String, Codable {
  case published
  case scheduled
  case draft
}
