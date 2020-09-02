//
//  ShowListView.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/26/20.
//

import SwiftUI
import NCSKit

struct ShowListView: View {
  @EnvironmentObject var application : NCSObject
  @Environment(\.imageCache) var cache: ImageCache
  
  func viewForError(_ error: Error) -> some View {
    
    Text(error.localizedDescription)
  }
  
  func viewForList(_ shows: [Show]) -> some View {
    List(shows) { (show) in
      HStack {
        show.imageURL.map{
          AsyncImage(url: $0, cache: self.cache, placeholder: EmptyView(), configuration: {$0.resizable()}).frame(height: 20.0)
        }
        
        Text(show.title)
      }
    }
  }
  
  var busyView : some View {
    Text("Loading...")
  }
  
  @ViewBuilder func mainView () -> some View {
    return EmptyView()
//    switch self.application.showsResult {
//    case .failure(let error): return  viewForError(error)
//    case .success(let shows): return viewForList(shows)
//    case .none: return busyView;
//    }
  }

    var body: some View {
      mainView()
      
    }
}

struct ShowListView_Previews: PreviewProvider {
    static var previews: some View {
        ShowListView()
    }
}
