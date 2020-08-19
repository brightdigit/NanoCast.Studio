//
//  TransistorObject.swift
//  NanoCastStudio WatchKit Extension
//
//  Created by Leo Dion on 8/19/20.
//

import Foundation
import Combine
import SwiftUI

struct EmptyError : Error {
  
}

extension Result {
  init (failure: Failure?, success: Success?, else: () -> Failure) {
    if let failure = failure {
      self = .failure(failure)
    } else if let success = success {
      self = .success(success)
    } else {
      self = .failure(`else`())
    }
  }
}
public class TransistorObject : ObservableObject {
  @Published var apiKey = ProcessInfo.processInfo.environment["TRANSISTORFM_API_KEY"] ?? ""
  @Published var userResult : Result<UserData, Error>?
  
  init () {
    let keychainAccessGroupName = "MLT7M394S7.com.brightdigit.NanoCastStudio"
    let itemKey = "TRANSISTORFM_API_KEY"
    let queryLoad: [String: AnyObject] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: itemKey as AnyObject,
      kSecReturnData as String: kCFBooleanTrue,
      kSecMatchLimit as String: kSecMatchLimitOne,
      kSecAttrAccessGroup as String: keychainAccessGroupName as AnyObject
    ]
    
    var result: AnyObject?

    let resultCodeLoad = withUnsafeMutablePointer(to: &result) {
      SecItemCopyMatching(queryLoad as CFDictionary, UnsafeMutablePointer($0))
    }
    
    if resultCodeLoad == noErr {
      if let result = result as? Data,
        let keyValue = NSString(data: result,
                                encoding: String.Encoding.utf8.rawValue) as String? {

        // Found successfully
        print(keyValue)
      }
    } else {
      let errorMessage =
        SecCopyErrorMessageString(resultCodeLoad, nil)
      
      
      print("Error loading from Keychain: \(errorMessage)")
    }
  }
  func beginSignin () {
    let decoder = JSONDecoder()
    let url = URL(string: "https://api.transistor.fm/v1?fields[user][]=name")!
    var request = URLRequest(url: url)
    request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      let result = Result(failure: error, success: data, else: EmptyError.init).flatMap { (data) in
        return Result{
          try decoder.decode(UserResponse.self, from: data)
        }
      }.map {  $0.data }
      DispatchQueue.main.async {
        self.userResult = result
      }
    }.resume()
  }
}
