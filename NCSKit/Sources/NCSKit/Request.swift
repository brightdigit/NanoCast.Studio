

public protocol Request {
  associatedtype AttributesType : AttributeSet
  
  var parameters : [String : Any]? { get }
  var data : [String : Any]? { get }
  var path : String { get }
  static var method : RequestMethod { get }
  
}
