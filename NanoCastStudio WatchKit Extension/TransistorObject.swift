//
//  TransistorObject.swift
//  NanoCastStudio WatchKit Extension
//
//  Created by Leo Dion on 8/19/20.
//

import Foundation
import Combine
import SwiftUI
import NCSKit


@available(*, deprecated)
public class TransistorObject : ObservableObject {
  @Published var apiKey = ProcessInfo.processInfo.environment["TRANSISTORFM_API_KEY"] ?? ""
  @Published var userResult : Result<QueryDataItem<UserAttributes>, Error>?
  
  init () {
   
  }
  
  func beginSignin () {
//    let decoder = JSONDecoder()
//    let url = URL(string: "https://api.transistor.fm/v1?fields[user][]=name")!
//    var request = URLRequest(url: url)
//    request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
//    URLSession.shared.dataTask(with: request) { (data, _, error) in
//      let result = Result(failure: error, success: data, else: EmptyError.init).flatMap { (data) in
//        return Result{
//          try decoder.decode(QueryResponse<UserAttributes>.self, from: data)
//        }
//      }.map {  $0.data }
//      DispatchQueue.main.async {
//        self.userResult = result
//      }
//    }.resume()
  }
}
