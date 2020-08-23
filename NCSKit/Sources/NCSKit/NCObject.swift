//
//  NCObject.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/19/20.
//

import Foundation
import Combine
import S3
import NIO

public struct S3Service {
  let bucket: String
  let s3 : S3
  
  public init () {
    s3 = S3(accessKeyId: "__", secretAccessKey: "__", region: .uswest2)
    bucket = "nanocaststudio-storage01"
  }
  
  public func uploadData(_ data : Data, with key: String) -> EventLoopFuture<URL> {
    let putObjectRequest = S3.PutObjectRequest(acl: .publicRead, body: data, bucket: bucket, contentLength: Int64(data.count), expires: TimeStamp(Date(timeIntervalSinceNow: 60 * 60 * 24)), key: key)
    
    let result = s3.putObject(putObjectRequest)
    return result.map { (output) in
      return URL(string: "https://\(bucket).s3-us-west-2.amazonaws.com/\(key)")!
    }

  }
  
  public func delete(key : String) -> EventLoopFuture<Void> {
    let request = S3.DeleteObjectRequest(bucket: bucket, key: key)
    return s3.deleteObject(request).map{_ in ()}
  }
  
}

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
      debugPrint(error)
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
  associatedtype AttributesType : AttributeSet
  
  var parameters : [String : Any]? { get }
  var data : [String : Any]? { get }
  static var path : String { get }
  static var method : RequestMethod { get }
  
}

extension Dictionary {
  mutating func forKey(_ key : Key, compactSet value: Value?) {
    if let value = value {
      self[key] = value
    }
  }
}
public struct EpisodeCreate {
  public init(show_id: Int, season : Int = 1, number: Int? = nil,  media_url: URL? = nil, title: String? = nil, summary: String? = nil) {
    self.number = number
    self.media_url = media_url
    self.title = title
    self.summary = summary
    self.show_id = show_id
    self.season = season
  }
  
  public let show_id : Int
  public let number : Int?
  public let media_url : URL?
  public let title : String?
  public let summary : String?
  public let season : Int
  
  var parameters : [String : Any] {
    var parameters = [String : Any]()
    
    var episode = [String : Any]()
    episode.forKey("season", compactSet: season)
    episode.forKey("number", compactSet: number)
    episode.forKey("media_url", compactSet: media_url)
    episode.forKey("title", compactSet: title)
    episode.forKey("summary", compactSet: summary)
    episode.forKey("show_id", compactSet: show_id)
    
    parameters["episode"] = episode
    return parameters
  }
  
}

public struct EpisodeCreateRequest : Request {
  
  
  public typealias AttributesType = EpisodeAttributes
  public static let path: String = "episodes"
  public static var method: RequestMethod = .post
  public let episode : EpisodeCreate
  
  public let parameters: [String : Any]? = nil
  
  public var data: [String : Any]? {
    return self.episode.parameters
  }
  
  public init (episode: EpisodeCreate) {
    self.episode = episode
  }
}

public extension Request {
  static var fields : [String : [String]]? {
    return AttributesType.fieldSet.map{
      [$0.resource : $0.fields]
    }
  }
}

public struct UserRequest : Request {
  public init () {}
  public static let path: String = ""
  
  public let parameters: [String : Any]? = nil
  public var data: [String : Any]? = nil
  
  public typealias AttributesType = UserAttributes
  
  public static var method  : RequestMethod = .get
}


public struct Pagination {
  let page : Int
  let per : Int
}

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

public struct TransistorService {
  
  public init () {
    
  }
  
  
  public func fetch<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, using session: URLSession, with decoder: JSONDecoder, atPage page: Pagination?, _ callback : @escaping ((Result<QueryResponse<AttributesType>, Error>) -> Void)) where RequestType.AttributesType == AttributesType {
    var url = URL(string: "https://api.transistor.fm/v1")!
    url.appendPathComponent(RequestType.path)
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    var queryItems = [URLQueryItem]()
    
    if let parameters = requestType.parameters {
    for (key, value) in parameters {
      queryItems.appendWithKey(key, value)
    }
    }
    
    if let page = page {
      queryItems.append(URLQueryItem(name: "pagination[per]", value: "\(page.per)"))
      queryItems.append(URLQueryItem(name: "pagination[page]", value: "\(page.page)"))
    }
    
    if let fieldSet = RequestType.fields {
      queryItems.appendWithKey("fields", fieldSet)
    }
    
    components.queryItems = queryItems
    
    var urlRequest = URLRequest(url: components.url!)
    urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    urlRequest.httpMethod = RequestType.method.rawValue
    
    if let data = requestType.data {
      var dictionary = [String : String]()
      for (key, value) in data {
        dictionary.setKey(key, withValue: value)
      }
      let postString = dictionary.map{ [$0.key, $0.value].joined(separator: "=")}.joined(separator: "&")
      print(postString)
      urlRequest.httpBody = postString.data(using: .utf8)
    }
    
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
  public func fetchAll<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, using session: URLSession, with decoder: JSONDecoder, on queue: DispatchQueue,  _ callback : @escaping ((Result<[QueryDataItem<AttributesType>], Error>) -> Void)) where RequestType.AttributesType == AttributesType {
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
      let barrierQueue = DispatchQueue(label: "transistor-queue", attributes: .concurrent)
      let group = DispatchGroup()
      for pageNumber in 2...metadata.totalPages {
        group.enter()
        queue.async {
          self.fetch(requestType, withAPIKey: apiKey, using: session, with: decoder, atPage: .init(page: pageNumber, per: response.data.count)) { (result) in
            barrierQueue.async(flags: .barrier) {
              responses.append(result)
              group.leave()
            }
          }
        }
      }
      
      group.notify(queue: queue){
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
