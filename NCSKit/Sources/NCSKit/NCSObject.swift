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
  let keychainService : KeychainService
  let transistorService = TransistorService()
  
  
  
  @Published public var loginApiKey = ""
  
  @Published public var userResult: Result<UserInfo, Error>?
  @Published private(set) var confirmedApiKey : String?
  
  
  @Published public private(set) var keychainError : Error?
  @Published public private(set) var apiError : Error?
  
  var cancellables  = [AnyCancellable]()
  
  public init (keychainService : KeychainService) {
    
    self.keychainService = keychainService
    //try! self.keychainService.clear()
    let userResultApiKeyPublisher = self.$userResult.compactMap{ $0 }.compactMap{ try? $0.get().apiKey }
    
//    let keychainServiceResultPublisher = self.$confirmedApiKey.compactMap{ $0 == nil ? () : nil }.flatMap { _ in
//      Timer.publish(every: 5.0, tolerance: 2.5, on: .current, in: .default, options: nil).autoconnect()
//    }.flatMap { _ in
//      return Future{ (resolve) in
//        self.ke
//      }
//    }
    
    let keychainSaveErrorPublisher = userResultApiKeyPublisher.tryMap { (apiKey)  in
      try self.keychainService.saveKey("TRANSISTORFM_API_KEY", withValue: apiKey, {_ in })
    }.map { $0 as? Error }.catch{ Just($0) }.compactMap{ $0 }
    
//
//    let keychainFetchErrorPublisher = keychainServiceResultPublisher.map { $0 as? Error }.catch{ Just($0) }.compactMap{ $0 }
    
//    keychainFetchErrorPublisher.merge(with: keychainSaveErrorPublisher).receive(on: DispatchQueue.main).print().sink { (error) in
//
//      self.keychainError = error
//    }.store(in: &cancellables)
//
//    let keychainServiceApiKeyPublisher = keychainServiceResultPublisher.replaceError(with: nil).compactMap{ $0 }
    
//    keychainServiceApiKeyPublisher.merge(with: userResultApiKeyPublisher).receive(on: DispatchQueue.main).sink { (apiKey) in
//      self.confirmedApiKey = apiKey
//    }.store(in: &self.cancellables)
    
    
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
      DispatchQueue.main.async {
        self.userResult = itemResult
      }
    }
  }
}
