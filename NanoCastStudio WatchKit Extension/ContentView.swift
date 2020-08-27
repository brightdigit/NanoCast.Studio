//
//  ContentView.swift
//  NanoCastStudio WatchKit Extension
//
//  Created by Leo Dion on 8/19/20.
//

import SwiftUI
import NCSKit

struct ContentView: View {
  @EnvironmentObject var application : NCSObject
  
  var requiresLogin : Bool {
    switch application.userResult {
    case .some(.success):
      return false
    default:
      return true
    }
  }
    var body: some View {
      ZStack{
        Group{
          if self.requiresLogin {
            LoginView()
          } else {
            ShowListView()
          }
        }
        EmptyView()
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
