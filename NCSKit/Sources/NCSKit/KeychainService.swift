import Foundation
import CryptoSwift
import CloudKit
public struct  KeychainService {

  let encryptionKey : Data
  
  
  init (encryptionKey: Data) {
    self.encryptionKey = encryptionKey
    let container = CKContainer(identifier: "iCloud.com.brightdigit.NanoCastStudio")
  }
  func clear () throws {
  }
  func fetchKey(_ key: String) throws -> String? {
    
//    if let data = dictionary[key] {
//      let actualData = data[0...(data.count-17)]
//      let iv = Data(data.suffix(16))
//      print(String(data: iv, encoding: .utf8))
//      print("Decypting \(actualData.count) bytes")
//      let aes = try AES(key: self.key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)
//      if let text = String(data: try actualData.decrypt(cipher: aes), encoding: .utf8) {
//        return text
//      }
//    }
    return nil
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
//    let actualData = value.data(using: .utf8)!
//    let ivChars = "1234567890123456".shuffled()
//    let ivString = String(ivChars)
//    let ivData = ivString.data(using: .utf8)!
//    print(ivString)
//    let data = actualData + ivData
//    let aes = try AES(key: self.key.bytes, blockMode: CBC(iv: ivData.bytes), padding: .pkcs7)
//    let encrypted = try actualData.encrypt(cipher: aes)
//    print("Encypted \(encrypted.count)")
//    self.dictionary[key] = encrypted + ivData
    //try keychain.set(value, key: key)
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
