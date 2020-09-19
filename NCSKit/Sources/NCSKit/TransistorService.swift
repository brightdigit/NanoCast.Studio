import Foundation

public struct TransistorService {
  
  public init () {
    
  }
  
  
  public func fetch<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, using session: URLSession, with decoder: JSONDecoder, atPage page: Pagination?, _ callback : @escaping ((Result<QueryResponse<AttributesType>, Error>) -> Void)) where RequestType.AttributesType == AttributesType {
    var url = URL(string: "https://api.transistor.fm/v1")!
    url.appendPathComponent(requestType.path)
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    var queryItems = [URLQueryItem]()
    
    if let parameters = requestType.parameters {
    for (key, value) in parameters {
      queryItems.appendWithKey(key, value)
    }
    }
    
    if let page = page {
      queryItems.append(URLQueryItem(name: "pagination[per]", value: "\(page.per)"))
      queryItems.append(URLQueryItem(name: "pagination[page]", value: "\(page.page)"))
    }
    
    if let fieldSet = RequestType.fields {
      queryItems.appendWithKey("fields", fieldSet)
    }
    
    components.queryItems = queryItems
    
    var urlRequest = URLRequest(url: components.url!)
    urlRequest.addValue(apiKey, forHTTPHeaderField: "x-api-key")
    urlRequest.httpMethod = RequestType.method.rawValue
    
    if let data = requestType.data {
      var dictionary = [String : String]()
      for (key, value) in data {
        dictionary.setKey(key, withValue: value)
      }
      let postString = dictionary.map{ [$0.key, $0.value].joined(separator: "=")}.joined(separator: "&")
      urlRequest.httpBody = postString.data(using: .utf8)
    }
    
    session.dataTask(with: urlRequest) { (data, _, error) in
      //print(String(data: data!, encoding: .utf8))
      let result = Result(failure: error, success: data, else: EmptyError.init).flatMap { (data) in
        Result {
          try decoder.decode(QueryResponse<AttributesType>.self, from: data)
        }
      }
      //debugPrint("completed", urlRequest.url, (try? result.get()) != nil)
      callback(result)
    }.resume()
  }

  
}

extension TransistorService {
  public func fetchAll<RequestType : Request, AttributesType>(_ requestType: RequestType, withAPIKey apiKey : String, using session: URLSession, with decoder: JSONDecoder, on queue: DispatchQueue,  _ callback : @escaping ((Result<[QueryDataItem<AttributesType>], Error>) -> Void)) where RequestType.AttributesType == AttributesType {
    self.fetch(requestType, withAPIKey: apiKey, using: session, with: decoder, atPage: nil) { (result) in
      let response : QueryResponse<AttributesType>
      switch result {
      case .success(let success): response = success
      case .failure(let error): return callback(.failure(error))
      }
      guard let metadata = response.meta else {
        callback(.success(Array(response.data)))
        return
      }
      guard metadata.totalPages > 1 else {

          callback(.success(Array(response.data)))
          return
      }
      var responses = [result]
      let barrierQueue = DispatchQueue(label: "transistor-queue", attributes: .concurrent)
      let group = DispatchGroup()
      for pageNumber in 2...metadata.totalPages {
        group.enter()
        queue.async {
          self.fetch(requestType, withAPIKey: apiKey, using: session, with: decoder, atPage: .init(page: pageNumber, per: response.data.count)) { (result) in
            barrierQueue.async(flags: .barrier) {
              responses.append(result)
              group.leave()
            }
          }
        }
      }

      group.notify(queue: queue){
        let responsesResult = Result {
          try responses.map{
            try $0.get()
          }
        }.map {
          $0.sorted { (lhs, rhs) -> Bool in
            let lhsPage = lhs.meta?.currentPage ?? -1
            let rhsPage = rhs.meta?.currentPage ?? -1
            return lhsPage <= rhsPage
          }.map { Array($0.data) }.flatMap{ $0 }
        }
        callback(responsesResult)
      }
    }
  }
  
  static func estimatedSeconds(forByteSize byteSize: Int) -> Int {
    return byteSize / 725000 + 20
  }
}


public extension TransistorService {
  func fetchAllEpisodes(withAPIKey apiKey: String, using session: URLSession, with decoder: JSONDecoder, on queue: DispatchQueue, _ callback: @escaping (Result<[Show], Error>) -> Void) {
    var shows = [Show]()
    let queue = DispatchQueue(label: "fetch-all-queue", attributes:  .concurrent)
    self.fetchAll(ShowsRequest(), withAPIKey: apiKey, using: session, with: decoder, on: queue) { (result) in
      let showAttrs : [QueryDataItem<ShowAttributes>]
      switch (result) {
      case .success(let showItems):
        showAttrs = showItems
      case .failure(let error):
        callback(.failure(error))
        return
      }
      let group = DispatchGroup()
      for item in showAttrs {
        group.enter()
        self.fetchAll(ListEpisodesRequest(showId: item.id), withAPIKey: apiKey, using: session, with: decoder, on: queue) { (result) in
          let episodes : [QueryDataItem<EpisodeAttributes>]
          switch (result) {
          case .success(let epItems):
            episodes = epItems
          case .failure(let error):
            callback(.failure(error))
            return
          }
          let show : Show
          do {
            show = try Show(show: item, episodes: episodes)
          } catch {
            callback(.failure(error))
            return
          }
          queue.async(flags: .barrier) {
            shows.append(show)
            group.leave()
          }
        }
      }
      group.notify(queue: queue) {
        callback(.success(shows))
      }
    }
    
  }
}
