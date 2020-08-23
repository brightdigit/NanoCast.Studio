import Foundation

public struct EpisodeAttributes : AttributeSet {
  public let number : Int?
  public let media_url : URL
  public let title : String
  public let summary : String?
  public let audio_processing: Bool
  public let status : EpisodeStatus
  public static let fieldSet : CustomFieldSet? = CustomFieldSet(resource: "episode", fields: ["audio_processing",
                                                         "number",
                                                         "media_url",
                                                         "title",
                                                         "summary",
  "status"]
  
  
  )
}
