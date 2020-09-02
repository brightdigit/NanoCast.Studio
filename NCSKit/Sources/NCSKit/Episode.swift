import Foundation

public struct Episode : Identifiable, Exportable {
  typealias EntityType = EpisodeEntity
  
  public let id : Int
  public let number : Int?
  public let mediaURL : URL
  public let title : String
  public let summary : String?
  public let status: EpisodeStatus
  
  func asImportable() -> EpisodeEntity.ImportSource {
    var importable = EpisodeEntity.ImportSource()
    importable["id"] = self.id
    importable["number"] = self.number
    importable["mediaURL"] = self.mediaURL
    importable["title"] = self.title
    importable["summary"] = self.summary
    importable["status"] = self.status
    return importable
    
  }
}
