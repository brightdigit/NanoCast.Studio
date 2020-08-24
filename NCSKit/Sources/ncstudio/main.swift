//
//  File.swift
//  
//
//  Created by Leo Dion on 8/20/20.
//

import Foundation
import NCSKit
import PromiseKit
import NIO
import Combine

//

//
//enum ParsingError : Error {
//  case idInvalidString(String)
//}
//extension Show {
//  public init (show: QueryDataItem<ShowAttributes>, episodes: [QueryDataItem<EpisodeAttributes>]) throws {
//    guard let id = Int(show.id) else {
//      throw ParsingError.idInvalidString(show.id)
//    }
//    
//    self.id = id
//    self.title = show.attributes.title
//    self.episodes = try episodes.map({ (item) in
//      guard let id = Int(item.id) else {
//        throw ParsingError.idInvalidString(show.id)
//      }
//      return Episode(id: id, number: item.attributes.number, media_url: item.attributes.media_url, title: item.attributes.title, summary: item.attributes.summary, status: item.attributes.status)
//    })
//  }
//}
//
//struct EpisodesRequest : Request {
//  
//  static var method: RequestMethod  = .get
//  
//  let showId : String
//  public init (showId : String) {
//    self.showId = showId
//  }
//  var parameters: [String : Any]? {
//    ["show_id" : self.showId]
//  }
//  let data: [String : Any]? = nil
//  static var path = "episodes"
//  
//  typealias AttributesType = EpisodeAttributes
//}
//
//struct ShowsRequest : Request {
//  let data: [String : Any]? = nil
//  
//  public init (query : String? = nil) {
//    self.query = query
//  }
//  let query : String?
//  
//  var parameters: [String : Any]? {
//    let pairs = query.map{
//      ("query", $0 as Any)
//    }
//    return Dictionary(uniqueKeysWithValues: [pairs].compactMap{$0})
//  }
//  
//  static var path: String = "shows"
//  
//  static var method: RequestMethod = .get
//  
//  typealias AttributesType = ShowAttributes
//  
//  
//}

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
        transistor.fetchAll(ListEpisodesRequest(showId: show.id), withAPIKey: apiKey, using: session, with: decoder, on: queue, resolver.resolve)
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

//0.01162721453 1895.165 22.035490036010742
//0.00167839488 64925.84 108.9711979627609
//1.38E-03*x + 19.4


var cancellable : Combine.Cancellable?

let url = URL(fileURLWithPath: "/Users/leo/Desktop/60secs.m4a")
let s3Service = S3Service(accessKeyId: ProcessInfo.processInfo.environment["AWS_ACCESS_KEY"], secretAccessKey: ProcessInfo.processInfo.environment["AWS_ACCESS_SECRET"], region: .uswest2, bucket: "nanocaststudio-storage01")
let data = try! Data(contentsOf: url)
let key = UUID().uuidString
var start : Date!
var end : Date!
s3Service.uploadData(data, with: key).whenComplete { (result) in
  let audio_url = try! result.get()
  let newEpisode = EpisodeCreate(show_id: show_id, audio_url: audio_url, title: title)
  let request = EpisodeCreateRequest(episode: newEpisode)
  start = Date()
  transistor.fetch(request, withAPIKey: apiKey, using: .shared, with: .init(), atPage: nil) { (result) in
    let id = try! result.get().data.first!.id
    let getReq = GetEpisodeRequest(episodeId: id)
//      //print(result)
//    let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (_) in
//
//    }
//
//    RunLoop.main.add(timer, forMode: .default)
    cancellable = RunLoop.main.schedule(after: .init(.init()), interval: .seconds(1), tolerance: .seconds(1), options: nil) {
      transistor.fetch(getReq, withAPIKey: apiKey, using: .shared, with: .init(), atPage: nil) { (result) in
        print(result)
        end = Date()
        let processing = try! result.get().data.first!.attributes.audio_processing
        if !processing {
          cancellable?.cancel()
          s3Service.delete(key: key).whenComplete { (result) in
            print(result)
            finished = true
          }
        }
      }
    }
    
       //finished = true
    }
  
 
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

cancellable = nil
let interval = end.timeIntervalSince(start)
print(data.count, interval)

