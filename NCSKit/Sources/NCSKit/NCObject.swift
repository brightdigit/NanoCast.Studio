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




//
//
//public struct TransistorService {
//
//  public init () {
//
//  }
//
//
//  public func fetch<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, using session: URLSession, with decoder: JSONDecoder, atPage page: Pagination?, _ callback : @escaping ((Result<QueryResponse<AttributesType>, Error>) -> Void)) where RequestType.AttributesType == AttributesType {
//    var url = URL(string: "https://api.transistor.fm/v1")!
//    url.appendPathComponent(RequestType.path)
//    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
//    var queryItems = [URLQueryItem]()
//
//    if let parameters = requestType.parameters {
//    for (key, value) in parameters {
//      queryItems.appendWithKey(key, value)
//    }
//    }
//
//    if let page = page {
//      queryItems.append(URLQueryItem(name: "pagination[per]", value: "\(page.per)"))
//      queryItems.append(URLQueryItem(name: "pagination[page]", value: "\(page.page)"))
//    }
//
//    if let fieldSet = RequestType.fields {
//      queryItems.appendWithKey("fields", fieldSet)
//    }
//
//    components.queryItems = queryItems
//
//    var urlRequest = URLRequest(url: components.url!)
//    urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
//    urlRequest.httpMethod = RequestType.method.rawValue
//
//    if let data = requestType.data {
//      var dictionary = [String : String]()
//      for (key, value) in data {
//        dictionary.setKey(key, withValue: value)
//      }
//      let postString = dictionary.map{ [$0.key, $0.value].joined(separator: "=")}.joined(separator: "&")
//      print(postString)
//      urlRequest.httpBody = postString.data(using: .utf8)
//    }
//
//    session.dataTask(with: urlRequest) { (data, _, error) in
//      print(String(data: data!, encoding: .utf8))
//      let result = Result(failure: error, success: data, else: EmptyError.init).flatMap { (data) in
//        Result {
//          try decoder.decode(QueryResponse<AttributesType>.self, from: data)
//        }
//      }
//      debugPrint("completed", urlRequest.url, (try? result.get()) != nil)
//      callback(result)
//    }.resume()
//  }
//
//  @available(*, deprecated)
//  func user (withAPIKey apiKey: String, callback: ((Result<QueryResponse<UserAttributes>, Error>) -> Void)) {
//
//  }
//
//  @available(*, deprecated)
//  func shows (withAPIKey apiKey: String, _ callback: ((Result<QueryResponse<ShowAttributes>, Error>) -> Void)) {
//
//  }
//
//  @available(*, deprecated)
//  func episodes(forShowWithId showId: Int, _ callback: ((Result<QueryResponse<EpisodeAttributes>, Error>) -> Void)) {
//  }
//
//}
//


//struct TransistorDatabase {
//
//}
//
//extension TransistorService {
//
//
//
//  func refresh (withAPIKey apiKey: String, _ callback:  ((Result<TransistorDatabase, Error>) -> Void)) {
//    self.shows(withAPIKey: apiKey) { (result) in
//      switch result {
//      case .failure(let error):
//        callback(.failure(error))
//      case .success(let showResponse): break
//      }
//    }
//  }
//
//}

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
