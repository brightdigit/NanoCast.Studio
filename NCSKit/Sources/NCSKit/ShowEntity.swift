//
//  File.swift
//  
//
//  Created by Leo Dion on 8/31/20.
//

import Foundation
import CoreStore

class ServiceEntity : CoreStoreObject {
  
}

class ShowEntity : CoreStoreObject {
  @Field.Stored("id")
  public var id : Int = -1
  
  @Field.Stored("title")
  public var title:String = ""
  
  @Field.Stored("imageURL")
  public var imageURL : URL?
//
//  init(id: Int, title: String, imageURL : URL? = nil){
//    self.id = id
//    self.title = title
//    self.imageURL = imageURL
//  }
//  @Field.Relationship(
//  public var episodes : [Episode]
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
public class EpisodeEntity : CoreStoreObject {
  
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
}
