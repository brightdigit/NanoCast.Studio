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
  
  func viewForError(_ error: Error) -> some View {
    Text(error.localizedDescription)
  }
  
  func viewForList(_ user: UserInfo) -> some View {
    Text(user.attributes.name)
  }
  
  var busyView : some View {
    Text("Loading...")
  }
  
  @ViewBuilder func mainView () -> some View {
    switch self.application.userResult {
    case .failure(let error): viewForError(error)
    case .success(let user): viewForList(user)
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
