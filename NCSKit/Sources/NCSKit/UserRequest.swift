


public struct UserRequest : Request {
  public init () {}
  public static let path: String = ""
  
  public let parameters: [String : Any]? = nil
  public var data: [String : Any]? = nil
  
  public typealias AttributesType = UserAttributes
  
  public static var method  : RequestMethod = .get
}
