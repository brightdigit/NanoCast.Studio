//
//  File.swift
//  
//
//  Created by Leo Dion on 8/31/20.
//

import Foundation
import CoreStore

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

public class ShowEntity : CoreStoreObject, NamedObject {
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
public class EpisodeEntity : CoreStoreObject, NamedObject {
  public static let entityName = "Episode"
  
  @Field.Stored("id")
  public var id : Int = -1
  @Field.Stored("number")
  public var number : Int?
  @Field.Stored("mediaURL")
  public var mediaURL : URL?
  @Field.Stored("title")
  public var title : String = ""
  @Field.Stored("id")
  public var summary : String?
  @Field.Stored("status")
  public var status: EpisodeStatus = .draft
  @Field.Relationship("show")
  public var show : ShowEntity?
}
