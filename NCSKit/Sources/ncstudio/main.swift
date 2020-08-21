//
//  File.swift
//  
//
//  Created by Leo Dion on 8/20/20.
//

import Foundation
import NCSKit
import PromiseKit

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
}.then(on: queue) { (showResponse) -> Promise<[QueryDataItem<EpisodeAttributes>]> in
  let promises = showResponse.data.map { (show) in
    Promise<QueryResponse<EpisodeAttributes>>{ (resolver) in
      transistor.fetch(EpisodesRequest(showId: show.id), withAPIKey: apiKey, using: .shared, with: .init(), atPage: nil, resolver.resolve)
      }
    }

  return when(resolved: promises).map(on: queue){ (result) in
    result.compactMap{
      try? $0.get().data
    }.reduce([QueryDataItem<EpisodeAttributes>](), +)
  }
//    .map(on: queue) { (results) -> [QueryDataItem<EpisodeAttributes>] in
//    print(results)
//    return results.map{
//      [QueryDataItem<EpisodeAttributes>]($0.data) }.reduce([QueryDataItem<EpisodeAttributes>](), +)
//  }
  
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
