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
  public let number : Int
  public let media_url : URL
  public let title : String
  public let summary : String
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
  var parameters: [String : Any] {
    ["show_id" : self.showId]
  }
  static var path = "episodes"
  
  typealias AttributesType = EpisodeAttributes
}

struct ShowsRequest : Request {
  
  public init (query : String? = nil) {
    self.query = query
  }
  let query : String?
  
  var parameters: [String : Any] {
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


let promise = Promise { (resolver) in

  transistor.fetch(UserRequest(), withAPIKey: apiKey, using: .shared, with: .init(), atPage: nil, resolver.resolve)

}.then(on: queue) { (_) in
  Promise { (resolver) in
    transistor.fetch(ShowsRequest(), withAPIKey: apiKey, using: .shared, with: .init(), atPage: nil, resolver.resolve)
  }
}.then(on: queue) { (showResponse) -> Promise<[Show]> in
  let promises = showResponse.data.map { (show) in
    Promise<[QueryDataItem<EpisodeAttributes>]>{ (resolver) in
      transistor.fetchAll(EpisodesRequest(showId: show.id), withAPIKey: apiKey, using: .shared, with: .init(), resolver.resolve)
    }.recover { _ in
      return Guarantee.value([QueryDataItem<EpisodeAttributes>]())
    }.map(on: queue) { (episodes) in
      try Show(show: show, episodes: episodes)
    }
  }

  return when(fulfilled: promises)
}.done { (result) in
  print(result)
  finished = true
}.catch { (error) in
  print (error)
  finished = true
}


while !finished {
  RunLoop.main.run(until: .distantPast)
}
