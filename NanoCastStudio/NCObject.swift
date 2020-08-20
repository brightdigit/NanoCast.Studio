//
//  NCObject.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/19/20.
//

import Foundation
import Combine

struct KeychainService {
  let groupName = "MLT7M394S7.com.brightdigit.NanoCastStudio"
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

/*
 {"data":[{"id":"122","type":"show","attributes":{"title":"Empower Apps"},"relationships":{}},{"id":"13364","type":"show","attributes":{"title":"NanoCast Studio Podcast"},"relationships":{}},{"id":"216","type":"show","attributes":{"title":"OK Productive"},"relationships":{}}],"meta":{"currentPage":1,"totalPages":1,"totalCount":3}}
 
 */


struct QueryDataItem<AttributesType : Codable> : Codable {
  let id : Int
  let type : String
  let attributes : AttributesType
}

struct QueryResponseMetadata : Codable {
  let currentPage : Int
  let totalPages : Int
  let totalCount : Int
}

struct QueryResponse<AttributesType : Codable> : Codable {
  let data : QueryDataItem<AttributesType>
  let meta : QueryResponseMetadata?
}


protocol Request {
  associatedtype AttributesType : Codable
  
}

struct TransistorService {
  
  func fetch<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, atPage page: Int?, _ callback : ((Result<QueryResponse<AttributesType>, Error>) -> Void)) where RequestType.AttributesType == AttributesType {
    
  }

  func signIn (withAPIKey apiKey: String, callback: ((Result<QueryResponse<UserAttributes>, Error>) -> Void)) {
    
  }
  
  func shows (withAPIKey apiKey: String, _ callback: ((Result<QueryResponse<ShowAttributes>, Error>) -> Void)) {
    
  }
  
  func episodes(forShowWithId showId: Int, _ callback: ((Result<QueryResponse<EpisodeAttributes>, Error>) -> Void)) {
  }
  
}

struct TransistorDatabase {
  
}

extension TransistorService {
  
  
  
  func refresh (withAPIKey apiKey: String, _ callback:  ((Result<TransistorDatabase, Error>) -> Void)) {
    self.shows(withAPIKey: apiKey) { (result) in
      switch result {
      case .failure(let error):
        callback(.failure(error))
      case .success(let showResponse): break
      }
    }
  }
  
}

public class NCObject : ObservableObject {
  let keychainService = KeychainService()
  let transistorService = TransistorService()
  
  
  
  @Published var apiKey = ""
  
  @Published private(set) var userResult : Result<QueryResponse<UserAttributes>, Error>?
  @Published private(set) var keyChainError : Error?
  
  init () {
    let apiKeyPublisher = self.$userResult.compactMap{ try? $0?.get() }.map{ _ in self.apiKey }
    apiKeyPublisher.tryMap {
      try self.keychainService.saveKey("apiKey", withValue: $0)
    }.map{ $0 as? Error }.catch{Just($0 as? Error)}.sink {
      self.keyChainError = $0
    }
    
    
    
  }
  
  func signIn () {
    self.transistorService.signIn(withAPIKey: self.apiKey) {
      self.userResult = $0
    }
  }
}
