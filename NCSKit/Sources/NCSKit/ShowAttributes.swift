import Foundation

public struct ShowAttributes : AttributeSet {
  public let title : String
  public let image_url : URL?
  public static let fieldSet : CustomFieldSet? = CustomFieldSet(resource: "show", fields: ["title", "image_url"])
}
