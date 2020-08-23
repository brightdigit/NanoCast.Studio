

public struct ShowAttributes : AttributeSet {
  public let title : String
  public static let fieldSet : CustomFieldSet? = CustomFieldSet(resource: "show", fields: ["title"])
}
