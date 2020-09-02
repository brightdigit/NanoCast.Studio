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
import CoreStore

extension Result {
  var error : Error? {
    switch self {
    case .failure(let error): return error
    default: return nil
    }
  }
}

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

extension UserDefaults {
  @objc public var apiKey : String? {
    get {
      return self.string(forKey: "TRANSISTORFM_API_KEY")
    }
    set {
      self.setValue(newValue, forKey: "TRANSISTORFM_API_KEY")
    }
  }
}

public class Observer : ListObserver {
  public func listMonitorDidRefetch(_ monitor: ListMonitor<ShowEntity>) {
    
  }
  
  
  public typealias ListEntityType = ShowEntity
  
  public func listMonitorDidChange(_ monitor: ListMonitor<ShowEntity>) {
    
  }
}

public class Database  {
  
  let dataStack : DataStack
  let storage : StorageInterface
  
  init () {
    let schema = CoreStoreSchema(modelVersion: "1", entities: [
      Entity<ServiceEntity>(),
      Entity<ShowEntity>(),
      Entity<EpisodeEntity>()
    ])
    
    let stack = DataStack(schema)
    
//    stack.perform { (transaction) in
//      transaction.importObject(<#T##into: Into<ImportableObject>##Into<ImportableObject>#>, source: <#T##ImportableObject.ImportSource#>)
//    } completion: { (result) in
//
//    }

//    stack.addStorage() { (<#Result<StorageInterface, CoreStoreError>#>) in
//      <#code#>
//    }
    self.storage = SQLiteStore(fileName: "NCS.sqlite")
    self.dataStack = stack
    
    let monitor = dataStack.monitorList(From<ShowEntity>())
    //monitor.addObserver(self)
    //let stack = DataStack()
    //stack.addStorage(<#T##storage: StorageInterface##StorageInterface#>, completion: <#T##(Result<StorageInterface, CoreStoreError>) -> Void#>)
    //stack.addStorage(<#T##storage: StorageInterface##StorageInterface#>, completion: <#T##(Result<StorageInterface, CoreStoreError>) -> Void#>)
  }
  
  func syncronize(shows : [Show], _ completion: @escaping (Error?) -> Void) {
    let showsImport = shows.map{  $0.asImportable() }
    
    self.dataStack.perform { (transaction) in
      try transaction.importUniqueObjects(Into<ShowEntity>(), sourceArray: showsImport)
    } completion: { (result) in
      completion(result.error)
    }

  }
  
  public func listMonitorDidChange(_ monitor: ListMonitor<ShowEntity>) {
    
  }
  
  public func listMonitorDidChange(_ monitor: ListMonitor<EpisodeEntity>) {
    
  }
  
}


public protocol Configuration {
  var encryptionKey : Data { get }
}

public class NCSObject : ObservableObject {
  let keychainService : KeychainService
  let transistorService = TransistorService()
  let localDB = Database()
  
  let decoder = JSONDecoder()
  
  @Published public var loginApiKey = ProcessInfo.processInfo.environment["TRANSISTORFM_API_KEY"] ?? ""
  
  @Published public var userResult: Result<UserInfo, Error>?
  //@Published public var showsResult: Result<[Show], Error>?
  
  @Published public private(set) var keychainError : Error?
  @Published public private(set) var apiError : Error?
  @Published public private(set) var dataError : Error?
  
  var cancellables  = [AnyCancellable]()
  let queue = DispatchQueue(label: "episodes-fetch", qos: .utility)
  
  public init (configuration: Configuration) {
    self.keychainService  = KeychainService(encryptionKey:  configuration.encryptionKey)
    let userResultApiKeyPublisher = self.$userResult.compactMap{ $0 }.compactMap{ try? $0.get().apiKey }
    
    
    
    let transistorEpisodesPublisher =  userResultApiKeyPublisher.flatMap { (apiKey) in
      Future{ (resolver) in
        self.transistorService.fetchAllEpisodes(withAPIKey: apiKey, using: .shared, with: self.decoder, on: self.queue) {
          resolver(.success($0))
        }
      }
    }
    
    transistorEpisodesPublisher.compactMap{ $0.error }.receive(on: DispatchQueue.main).sink {
      self.apiError = $0
    }.store(in: &self.cancellables)
    
    transistorEpisodesPublisher.compactMap{ try? $0.get() }.flatMap { (shows) in
      Future{ (resolver) in
        self.localDB.syncronize(shows: shows) { (error) in
          resolver(.success(error))
        }
      }
    }.sink {
      self.dataError = $0
    }.store(in: &self.cancellables)
    
    userResultApiKeyPublisher.flatMap { (apiKey) in
      Future{ (resolver) in
        self.keychainService.saveKey(apiKey) {
          resolver(.success($0))
        }
      }
    }.receive(on: DispatchQueue.main).sink { (error) in
      self.keychainError = error
    }.store(in: &self.cancellables)
   
      
    keychainService.defaults.publisher(for: \.apiKey).compactMap{ $0 }.sink {
      self.signIn(withApiKey: $0)
    }.store(in: &self.cancellables)
    
    keychainService.refresh { (result) in
      if case let .failure(error) = result {
        DispatchQueue.main.async {
          self.keychainError = error
        }
      }
    }
    
    if let apiKey = ProcessInfo.processInfo.environment["TRANSISTORFM_API_KEY"] {
      self.loginApiKey = apiKey
    }
  }
  
  public func signIn (withApiKey apiKey: String? = nil) {
    let apiKey = apiKey ?? self.loginApiKey
    let request = UserRequest()
    self.transistorService.fetch(request, withAPIKey: apiKey, using: .shared, with: .init(), atPage: nil) { (result) in
      
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
  
  public func beginSubscription () {
    self.keychainService.beginSubscription()
  }
  
  public func refresh (_ completion: @escaping ((Result<String?, Error>) -> Void)) {
    self.keychainService.refresh(
      completion
    )
  }
}
