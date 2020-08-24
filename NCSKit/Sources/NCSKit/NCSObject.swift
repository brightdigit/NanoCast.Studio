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

typealias KeyPathOnObject<Output, Root> = (Root, ReferenceWritableKeyPath<Root, Output>)

extension Publisher where Self.Failure == Never {
    public func assignNoRetain<Root>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable where Root: AnyObject {
        sink { [weak object] (value) in
        object?[keyPath: keyPath] = value
    }
  }
  
  func assign<CollectionType, Root>(to published: inout Published<Self.Output>.Publisher, or keyPathObject: KeyPathOnObject<Self.Output, Root>, storeIn collection: inout CollectionType) where Self.Failure == Never, CollectionType : RangeReplaceableCollection, CollectionType.Element == AnyCancellable {
    
    if #available(iOS 14.0, watchOS 7.0, OSX 11.0, *) {
        self.assign(to: &published)
    } else {
      self.assign(to: keyPathObject.1, on: keyPathObject.0).store(in: &collection)
    }
  }
}
public struct UserInfo {
  public let apiKey : String
  public let attributes : UserAttributes
}

public class NCSObject : ObservableObject {
  let keychainService = KeychainService()
  let transistorService = TransistorService()
  
  
  
  @Published public var loginApiKey = ""
  
  @Published public var userResult: Result<UserInfo, Error>?
  @Published private(set) var confirmedApiKey : String?
  
  
  @Published public private(set) var keyChainError : Error?
  @Published public private(set) var apiError : Error?
  
  var cancellables  = [AnyCancellable]()
  
  public init () {
    let userResultApiKeyPublisher = self.$userResult.compactMap{ try? $0?.get() }.map{$0.apiKey}
    
    let keychainServiceApiKeyPublisher = self.$confirmedApiKey.compactMap{ $0 == nil ? () : nil }.flatMap { _ in
      Timer.publish(every: 5.0, tolerance: 2.5, on: .current, in: .default, options: nil).autoconnect()
    }.tryCompactMap { _ in
      try self.keychainService.fetchKey("TRANSISTORFM_API_KEY")
    }
  }
  
  public func signIn () {
    let apiKey = self.loginApiKey
    let request = UserRequest()
    self.transistorService.fetch(request, withAPIKey: self.loginApiKey, using: .shared, with: .init(), atPage: nil) { (result) in
      
      let itemResult = result.flatMap { (response) -> Result<UserInfo, Error> in
        guard let item = response.data.first else {
          return .failure(EmptyError())
        }
        
        return .success(UserInfo(apiKey:apiKey, attributes: item.attributes))
      }
      self.userResult = itemResult
    }
  }
}
