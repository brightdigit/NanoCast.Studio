import Foundation

public struct UserAttributes : AttributeSet {
  public let name : String
  public static let fieldSet : CustomFieldSet? = CustomFieldSet(resource: "user", fields: ["name"])
}
