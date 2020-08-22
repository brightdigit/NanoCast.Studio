import Foundation

public struct CustomFieldSet {
  let resource : String
  let fields : [String]
}

public protocol AttributeSet : Codable {
  static var fieldSet : CustomFieldSet? { get }
}
public struct UserAttributes : AttributeSet {
  public let name : String
  public static let fieldSet : CustomFieldSet? = CustomFieldSet(resource: "user", fields: ["name"])
}

public struct ShowAttributes : AttributeSet {
  public let title : String
  public static let fieldSet : CustomFieldSet? = CustomFieldSet(resource: "show", fields: ["title"])
}

public struct EpisodeAttributes : AttributeSet {
  public let number : Int
  public let media_url : URL
  public let title : String
  public let summary : String
  public static let fieldSet : CustomFieldSet? = CustomFieldSet(resource: "episode", fields: [
                                                         "number",
                                                         "media_url",
                                                         "title",
                                                         "summary"]
  
  
  )
}

public enum EpisodeStatus : String, Codable {
  case published
  case scheduled
  case draft
}
