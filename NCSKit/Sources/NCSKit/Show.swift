import Foundation

public struct Show : Identifiable {
  public let id : Int
  public let title : String
  public let episodes : [Episode]
  public let imageURL : URL?

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
      return Episode(id: id, number: item.attributes.number, media_url: item.attributes.media_url, title: item.attributes.title, summary: item.attributes.summary, status: item.attributes.status)
    })
  }
}
