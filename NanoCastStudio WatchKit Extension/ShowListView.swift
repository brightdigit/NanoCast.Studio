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
    switch self.application.showsResult {
    case .failure(let error): viewForError(error)
    case .success(let shows): viewForList(shows)
    case .none: busyView;
    }
  
    
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
