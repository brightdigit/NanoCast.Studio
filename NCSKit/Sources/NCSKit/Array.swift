import Foundation

extension Array where Element == URLQueryItem {
  mutating func appendWithKey(_ key: String, _ value: Any) {
    if let dictionary = value as? [String : Any] {
      for (subKey, subValue) in dictionary {
        self.appendWithKey("\(key)[\(subKey)]", subValue)
      }
    } else if let array = value as? [Any] {
      for subValue in array {
        self.appendWithKey("\(key)[]", subValue)
      }
    } else {
      self.append(URLQueryItem(name: key, value: "\(value)"))
    }
  }
}

