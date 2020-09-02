import Foundation
import CoreStore

protocol Exportable {
  associatedtype EntityType : ImportableObject
  func asImportable () -> EntityType.ImportSource
}
public struct Show : Identifiable, Exportable {
  typealias EntityType = ShowEntity
  
  public let id : Int
  public let title : String
  public let episodes : [Episode]
  public let imageURL : URL?
  
  func asImportable () -> ShowEntity.ImportSource {
    var importable = ShowEntity.ImportSource()
    importable["id"] = self.id
    importable["title"] = self.title
    importable["imageURL"] = self.imageURL
    importable["episodes"] = self.episodes.map{ $0.asImportable() }
    return importable
  }
}


extension Show {
  public init (show: QueryDataItem<ShowAttributes>, episodes: [QueryDataItem<EpisodeAttributes>]) throws {
    guard let id = Int(show.id) else {
      throw ParsingError.idInvalidString(show.id)
    }
    
    self.id = id
    self.title = show.attributes.title
    self.imageURL = show.attributes.image_url
    self.episodes = try episodes.map({ (item) in
      guard let id = Int(item.id) else {
        throw ParsingError.idInvalidString(show.id)
      }
      return Episode(id: id, number: item.attributes.number, mediaURL: item.attributes.media_url, title: item.attributes.title, summary: item.attributes.summary, status: item.attributes.status)
    })
  }
}

