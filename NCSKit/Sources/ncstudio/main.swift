//
//  File.swift
//  
//
//  Created by Leo Dion on 8/20/20.
//

import Foundation
import NCSKit
import PromiseKit

public struct Episode {
  public let id : Int
  public let number : Int?
  public let media_url : URL
  public let title : String
  public let summary : String?
}

public struct Show {
  public let id : Int
  public let title : String
  public let episodes : [Episode]
  
  
}

enum ParsingError : Error {
  case idInvalidString(String)
}
extension Show {
  public init (show: QueryDataItem<ShowAttributes>, episodes: [QueryDataItem<EpisodeAttributes>]) throws {
    guard let id = Int(show.id) else {
      throw ParsingError.idInvalidString(show.id)
    }
    
    self.id = id
    self.title = show.attributes.title
    self.episodes = try episodes.map({ (item) in
      guard let id = Int(item.id) else {
        throw ParsingError.idInvalidString(show.id)
      }
      return Episode(id: id, number: item.attributes.number, media_url: item.attributes.media_url, title: item.attributes.title, summary: item.attributes.summary)
    })
  }
}

struct EpisodesRequest : Request {
  
  static var method: RequestMethod  = .get
  
  let showId : String
  public init (showId : String) {
    self.showId = showId
  }
  var parameters: [String : Any]? {
    ["show_id" : self.showId]
  }
  let data: [String : Any]? = nil
  static var path = "episodes"
  
  typealias AttributesType = EpisodeAttributes
}

struct ShowsRequest : Request {
  let data: [String : Any]? = nil
  
  public init (query : String? = nil) {
    self.query = query
  }
  let query : String?
  
  var parameters: [String : Any]? {
    let pairs = query.map{
      ("query", $0 as Any)
    }
    return Dictionary(uniqueKeysWithValues: [pairs].compactMap{$0})
  }
  
  static var path: String = "shows"
  
  static var method: RequestMethod = .get
  
  typealias AttributesType = ShowAttributes
  
  
}

guard let apiKey = ProcessInfo.processInfo.environment["TRANSISTORFM_API_KEY"] else {
  print("Missing API KEY")
  exit(1)
}

let transistor = TransistorService()

let queue = DispatchQueue.global(qos: .userInitiated)
var finished = false

func fetchAllEpisodes(withAPIKey apiKey: String, using session: URLSession, with decoder: JSONDecoder, on queue: DispatchQueue) -> Promise<[Show]> {
  let promise = Promise { (resolver) in

    transistor.fetch(UserRequest(), withAPIKey: apiKey, using: session, with: decoder, atPage: nil, resolver.resolve)

  }.then(on: queue) { (_) in
    Promise { (resolver) in
      transistor.fetch(ShowsRequest(), withAPIKey: apiKey, using: session, with: decoder, atPage: nil, resolver.resolve)
    }
  }.then(on: queue) { (showResponse) -> Promise<[Show]> in
    let promises = showResponse.data.map { (show) in
      Promise<[QueryDataItem<EpisodeAttributes>]>{ (resolver) in
        transistor.fetchAll(EpisodesRequest(showId: show.id), withAPIKey: apiKey, using: session, with: decoder, on: queue, resolver.resolve)
      }.recover { _ in
        return Guarantee.value([QueryDataItem<EpisodeAttributes>]())
      }.map(on: queue) { (episodes) in
        try Show(show: show, episodes: episodes)
      }
    }

    return when(fulfilled: promises)
  }
  
  return promise
}

let show_id = 13364

let title = names.randomElement()!

let newEpisode = EpisodeCreate(show_id: show_id, title: title)

let url = URL(fileURLWithPath: "/Users/leo/Desktop/test.jpeg")
let s3Service = S3Service()
let data = try! Data(contentsOf: url)
let key = UUID().uuidString
s3Service.uploadData(data, with: key).flatMap { (_) in
  s3Service.delete(key: key)
}.whenComplete { (result) in
  print(result)
  finished = true
}
//transistor.fetch(EpisodeCreateRequest(episode: newEpisode), withAPIKey: apiKey, using: .shared, with: .init(), atPage: nil) { (result) in
//  print(result)
//  finished = true
//}
//
//
//fetchAllEpisodes(withAPIKey: apiKey, using: .shared, with: .init(), on: queue).done { (result) in
//  print(result)
//  finished = true
//}.catch { (error) in
//  print (error)
//  finished = true
//}


while !finished {
  RunLoop.main.run(until: .distantPast)
}
