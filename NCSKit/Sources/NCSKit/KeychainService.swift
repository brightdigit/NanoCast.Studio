import Foundation
import KeychainAccess

public struct KeychainService {
  let groupName = "MLT7M394S7.com.brightdigit.NanoCastStudio"
  let keychain = Keychain(accessGroup: "MLT7M394S7.com.brightdigit.NanoCastStudio")
  
  func clear () throws {
    try Keychain(service: "MLT7M394S7.com.brightdigit.NanoCastStudio").synchronizable(true).removeAll()
  }
  func fetchKey(_ key: String) throws -> String? {
    print("fetching key")
    debugPrint(keychain.allKeys())
    return try keychain.getString(key)
//    let queryLoad: [String: AnyObject] = [
//      kSecClass as String: kSecClassGenericPassword,
//      kSecAttrAccount as String: key as AnyObject,
//      kSecReturnData as String: kCFBooleanTrue,
//      kSecMatchLimit as String: kSecMatchLimitOne,
//      kSecAttrAccessGroup as String: self.groupName as AnyObject,
//      kSecAttrSynchronizable as String: kCFBooleanTrue
//    ]
//
//    var result: AnyObject?
//
//    let resultCodeLoad = withUnsafeMutablePointer(to: &result) {
//      SecItemCopyMatching(queryLoad as CFDictionary, UnsafeMutablePointer($0))
//    }
//
//
//
//    if resultCodeLoad == noErr {
//      if let result = result as? Data {
//        return String(data: result, encoding: .utf8)
//      }
//      preconditionFailure()
//    } else if resultCodeLoad == errSecItemNotFound {
//      return nil
//    } else {
//      throw SecError(code: resultCodeLoad)
//    }
  }
  
  func saveKey(_ key: String, withValue value: String) throws {
    try keychain.set(value, key: key)
    //Keychain(accessGroup: "MLT7M394S7.com.brightdigit.NanoCastStudio").synchronizable(true)[key] = value
//    guard let valueData = value.data(using: String.Encoding.utf8) else {
//      print("Error saving text to Keychain")
//      return
//    }
//
//    let queryAdd: [String: AnyObject] = [
//      kSecClass as String: kSecClassGenericPassword,
//      kSecAttrAccount as String: key as AnyObject,
//      kSecValueData as String: valueData as AnyObject,
//      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
//      kSecAttrAccessGroup as String: self.groupName as AnyObject
//    ]
//
//    let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
//
//    if resultCode != noErr {
//      throw SecError(code: resultCode)
//    }
  }
}
