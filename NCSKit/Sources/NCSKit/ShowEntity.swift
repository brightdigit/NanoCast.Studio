//
//  File.swift
//  
//
//  Created by Leo Dion on 8/31/20.
//

import Foundation
import CoreStore

enum Errors : Error {
  case missingRequired(String)
  case invalidConversion(Any)
}


extension Dictionary where Key == String, Value == Any {
  func get<ValueType>(_ valueType: ValueType.Type, key: String) throws -> ValueType? {
    guard let anyValue = self[key] else {
      return nil
    }
    
    guard let value = anyValue as? ValueType else {
      throw Errors.invalidConversion(anyValue)
    }
    
    return value
  }
  
  func required<ValueType>(_ valueType: ValueType.Type, key: String) throws -> ValueType {
    guard let value = try self.get(valueType, key: key) else {
      throw Errors.missingRequired(key)
    }
    return value
  }
  
//  func get<ValueType>(key: String, _ defaultValue: ValueType) throws -> ValueType {
//    return self.get(type(of: defaultValue), key: key) ?? defaultValue
//  }
}

extension Entity where O : NamedObject {
  convenience init() {
    self.init(O.self.entityName)
  }
}

public protocol NamedObject : CoreStoreObject {
  static var entityName : String { get }
}

public class ServiceEntity : CoreStoreObject, NamedObject {
  public static let entityName = "Service"
  
  @Field.Relationship("shows", inverse: \.$service)
  public var shows : Set<ShowEntity>
}

public class ShowEntity : CoreStoreObject, NamedObject, ImportableUniqueObject {
  public static let uniqueIDKeyPath: String = #keyPath(ShowEntity.id)
  
  public static func uniqueID(from source: [String : Any], in transaction: BaseDataTransaction) throws -> Int? {
    return source["id"] as? Int
  }
  
  public func update(from source: [String : Any], in transaction: BaseDataTransaction) throws {
    self.id = try source.required(Int.self, key: "id")
    self.title = try source.required(String.self, key: "title")
    self.imageURL = try source.required(URL.self, key: "imageURL")
    //        self.exchanges = try! NSSet(array: transaction.importUniqueObjects(Into<Exchange>(), sourceArray: source["exchanges"].array!))
    let episodesProp  = try source.required([EpisodeEntity.ImportSource].self, key: "episodes")
    let episodeArray = try transaction.importUniqueObjects(Into<EpisodeEntity>(), sourceArray: episodesProp)
    let episodes = Set(episodeArray)
    self.episodes = episodes
  
  }
  
  public typealias UniqueIDType = Int
  
  public typealias ImportSource = [ String : Any ]
  
  public static let entityName = "Show"
  
  @objc
  @Field.Stored("id")
  public var id : Int = -1
  
  @Field.Stored("title")
  public var title:String = ""
  
  @Field.Stored("imageURL")
  public var imageURL : URL?
  
  @Field.Relationship("service")
  public var service : ServiceEntity?
  
  @Field.Relationship("episodes", inverse: \.$show)
  public var episodes : Set<EpisodeEntity>
}

extension EpisodeStatus : FieldStorableType {
  public static func cs_fromFieldStoredNativeType(_ value: String) -> EpisodeStatus {
    return EpisodeStatus(rawValue: value)!
  }
  
  public func cs_toFieldStoredNativeType() -> Any? {
    return self.rawValue
  }
  
  public typealias FieldStoredNativeType = String
  
  
}
public class EpisodeEntity : CoreStoreObject, NamedObject, ImportableUniqueObject {
  public static let entityName = "Episode"
  
  @objc
  @Field.Stored("id")
  public var id : Int = -1
  @Field.Stored("number")
  public var number : Int?
  @Field.Stored("mediaURL")
  public var mediaURL : URL?
  @Field.Stored("title")
  public var title : String = ""
  @Field.Stored("summary")
  public var summary : String?
  @Field.Stored("status")
  public var status: EpisodeStatus = .draft
  @Field.Relationship("show")
  public var show : ShowEntity?
  
  public static let uniqueIDKeyPath: String = #keyPath(EpisodeEntity.id)
  
  public static func uniqueID(from source: [String : Any], in transaction: BaseDataTransaction) throws -> Int? {
    return source["id"] as? Int
  }
  
  public func update(from source: [String : Any], in transaction: BaseDataTransaction) throws {
    self.id = try source.required(Int.self, key: "id")
    self.title = try source.required(String.self, key: "title")
    self.mediaURL = try source.get(URL.self, key: "mediaURL")
    self.number = try source.get(Int.self, key: "URL")
    self.summary = try source.get(String.self, key: "summary")
    self.status = try source.required(EpisodeStatus.self, key: "status")
    
  }
  
  public typealias UniqueIDType = Int
  
  public typealias ImportSource = [ String : Any ]
}
