//
//  NCObject.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/19/20.
//

import Foundation
import Combine

public struct EmptyError : Error {
  public init () {}
}

public extension Result {
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
public struct KeychainService {
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


public struct QueryDataItem<AttributesType : Codable> : Codable {
  public let id : String
  public let type : String
  public let attributes : AttributesType
}

public struct QueryResponseMetadata : Codable {
  public let currentPage : Int
  public let totalPages : Int
  public let totalCount : Int
}

public struct QueryResponse<AttributesType : Codable> : Codable {
  public let data : Many<QueryDataItem<AttributesType>>
  public let meta : QueryResponseMetadata?
}

public enum Many<Element : Codable> : Collection, Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    
    switch self {
    case .single(let item): try container.encode(item)
    case .plural(let items): try container.encode(items)
    }
  }
  
  public typealias Index = Array<Element>.Index
     
  public var startIndex: Index { return self.asArray().startIndex }
  public var endIndex: Index { return self.asArray().endIndex }

      // Required subscript, based on a dictionary index
  public subscript(index: Index) -> Element {
        get { return self.asArray()[index] }
      }

      // Method that returns the next index when iterating
  public func index(after i: Index) -> Index {
        return self.asArray().index(after: i)
      }
  
  private func asArray () -> Array<Element> {
    switch self {
    case .single(let item): return [item]
    case .plural(let items): return items
    }
  }
  
  case single(Element)
  case plural([Element])
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    
    do {
      let element = try container.decode(Element.self)
      self = .single(element)
      return
    } catch {
      // debugPrint(error)
    }
    self = try .plural(container.decode([Element].self))
    
  }
}

public enum RequestMethod: String {
  case get = "GET"
  case delete = "DELETE"
  case post = "POST"
  case patch = "PATCH"
}

public protocol Request {
  associatedtype AttributesType : Codable
  
  var parameters : [String : Any] { get }
  static var path : String { get }
  static var method : RequestMethod { get }
  
}


public struct UserRequest : Request {
  public init () {}
  public static let path: String = ""
  
  public let parameters: [String : Any] = [String : Any]()
  
  public typealias AttributesType = UserAttributes
  
  public static var method  : RequestMethod = .get
}


public struct Pagination {
  let page : Int
  let per : Int
}

public struct TransistorService {
  
  public init () {
    
  }
  public func fetch<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, using session: URLSession, with decoder: JSONDecoder, atPage page: Pagination?, _ callback : @escaping ((Result<QueryResponse<AttributesType>, Error>) -> Void)) where RequestType.AttributesType == AttributesType {
    var url = URL(string: "https://api.transistor.fm/v1")!
    url.appendPathComponent(RequestType.path)
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    var queryItems = [URLQueryItem]()
    for (key, value) in requestType.parameters {
      queryItems.append(URLQueryItem(name: key, value: "\(value)"))
    }
    
    if let page = page {
      queryItems.append(URLQueryItem(name: "pagination[per]", value: "\(page.per)"))
      queryItems.append(URLQueryItem(name: "pagination[page]", value: "\(page.page)"))
    }
    
    components.queryItems = queryItems
    
    var urlRequest = URLRequest(url: components.url!)
    urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    urlRequest.httpMethod = RequestType.method.rawValue
    
    session.dataTask(with: urlRequest) { (data, _, error) in
      let result = Result(failure: error, success: data, else: EmptyError.init).flatMap { (data) in
        Result {
          try decoder.decode(QueryResponse<AttributesType>.self, from: data)
        }
      }
      debugPrint("completed", urlRequest.url, (try? result.get()) != nil)
      callback(result)
    }.resume()
  }

  @available(*, deprecated)
  func user (withAPIKey apiKey: String, callback: ((Result<QueryResponse<UserAttributes>, Error>) -> Void)) {
    
  }
  
  @available(*, deprecated)
  func shows (withAPIKey apiKey: String, _ callback: ((Result<QueryResponse<ShowAttributes>, Error>) -> Void)) {
    
  }
  
  @available(*, deprecated)
  func episodes(forShowWithId showId: Int, _ callback: ((Result<QueryResponse<EpisodeAttributes>, Error>) -> Void)) {
  }
  
}

extension TransistorService {
  public func fetchAll<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, using session: URLSession, with decoder: JSONDecoder, _ callback : @escaping ((Result<[QueryDataItem<AttributesType>], Error>) -> Void)) where RequestType.AttributesType == AttributesType {
    self.fetch(requestType, withAPIKey: apiKey, using: session, with: decoder, atPage: nil) { (result) in
      let response : QueryResponse<AttributesType>
      switch result {
      case .success(let success): response = success
      case .failure(let error): return callback(.failure(error))
      }
      guard let metadata = response.meta else {
        callback(.success(Array(response.data)))
        return
      }
      guard metadata.totalPages > 1 else {
        
          callback(.success(Array(response.data)))
          return
      }
      var responses = [result]
      let queue = DispatchQueue(label: "transistor-queue", attributes: .concurrent)
      let group = DispatchGroup()
      for pageNumber in 2...metadata.totalPages {
        group.enter()
        self.fetch(requestType, withAPIKey: apiKey, using: session, with: decoder, atPage: .init(page: pageNumber, per: response.data.count)) { (result) in
          queue.async(flags: .barrier) {
            responses.append(result)
            group.leave()
          }
        }
      }
      group.notify(queue: .main){
        let responsesResult = Result {
          try responses.map{
            try $0.get()
          }
        }.map {
          $0.sorted { (lhs, rhs) -> Bool in
            let lhsPage = lhs.meta?.currentPage ?? -1
            let rhsPage = rhs.meta?.currentPage ?? -1
            return lhsPage <= rhsPage
          }.map { Array($0.data) }.flatMap{ $0 }
        }
        callback(responsesResult)
      }
    }
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
  
  
  
  @Published public var apiKey = ""
  
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
    self.transistorService.user(withAPIKey: self.apiKey) {
      self.userResult = $0
    }
  }
}
