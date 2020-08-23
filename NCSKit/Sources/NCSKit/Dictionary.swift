
extension Dictionary where Key == String, Value == String {
  mutating func setKey(_ key: String, withValue value: Any) {
    if let dictionary = value as? [String : Any] {
      for (subKey, subValue) in dictionary {
        self.setKey("\(key)[\(subKey)]", withValue: subValue)
      }
    } else if let array = value as? [Any] {
      for subValue in array {
        self.setKey("\(key)[]", withValue: subValue)
      }
    } else {
      self[key] = "\(value)"
    }
  }
}



extension Dictionary {
  mutating func forKey(_ key : Key, compactSet value: Value?) {
    if let value = value {
      self[key] = value
    }
  }
}
