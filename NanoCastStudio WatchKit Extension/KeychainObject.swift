//
//  KeychainObject.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/19/20.
//

import Foundation
import Combine

struct SecError : Error, LocalizedError {
  let code : OSStatus
  
  var errorDescription: String? {
    return SecCopyErrorMessageString(self.code, nil) as String?
  }
}

class KeychainObject : ObservableObject {
  @Published var apiKeyFetched : String?
  @Published var apiKey : String?
  let groupName = "MLT7M394S7.com.brightdigit.NanoCastStudio"
  var cancellables = [AnyCancellable]()
  init () {   
    
    self.$apiKey.filter{ $0 == nil }.flatMap { (_) in
      Timer.publish(every: 10.0, tolerance: 5.0, on: .main, in: .common, options: nil).autoconnect().tryMap {_ in
        try self.fetchKey("apiKey")
      }.replaceError(with: nil).compactMap{ $0 }
    }.sink {
      
        if self.apiKeyFetched != $0 {
      self.apiKeyFetched = $0
        }
    }.store(in: &cancellables)
    
    self.$apiKeyFetched.compactMap{ $0 }.sink {
      if self.apiKey != $0 {
        self.apiKey = $0
      }
    }.store(in: &cancellables)
    
    self.$apiKey.compactMap{ $0 }.sink {
      try? self.saveKey("apiKey", withValue: $0)
    }.store(in: &cancellables)
    
  }
  
  func fetchKey(_ key: String) throws -> String? {
    let queryLoad: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key as AnyObject,
      kSecReturnData as String: kCFBooleanTrue,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrAccessGroup as String: self.groupName as AnyObject,
      kSecAttrSynchronizable as String: kCFBooleanTrue
    ]
    
    var result: AnyObject?

    let resultCodeLoad = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(queryLoad as CFDictionary, UnsafeMutablePointer($0))
    }
    
    
    
    if resultCodeLoad == noErr {
      if let result = result as? Data {
        return String(data: result, encoding: .utf8)
      }
      preconditionFailure()
    } else if resultCodeLoad == errSecItemNotFound {
      return nil
    } else {
      throw SecError(code: resultCodeLoad)
    }
  }
  
  func saveKey(_ key: String, withValue value: String) throws {
    guard let valueData = value.data(using: String.Encoding.utf8) else {
      print("Error saving text to Keychain")
      return
    }

    let queryAdd: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: key as AnyObject,
      kSecValueData as String: valueData as AnyObject,
      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
      kSecAttrAccessGroup as String: self.groupName as AnyObject
    ]

    let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)

    if resultCode != noErr {
      throw SecError(code: resultCode)
    }
  }
}
