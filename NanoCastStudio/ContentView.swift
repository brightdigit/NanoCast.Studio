//
//  ContentView.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/18/20.
//


import SwiftUI
import NCSKit
extension View {
    @ViewBuilder func hidden(_ shouldHide: Bool) -> some View {
        switch shouldHide {
        case true: self.hidden()
        case false: self
        }
    }
}

struct ContentView: View {
  @EnvironmentObject var object : NCSObject
    var body: some View {
      NavigationView{
      ShowListView()
      }.sheet(isPresented: self.$object.requireLogin) {
        LoginView().environmentObject(self.object)
      }
//      NavigationView(content: {
//
//        Text("Woops!")
//        //ShowListView()
////        VStack{
////          TextField("API Key", text: $object.apiKey)
////        NavigationLink(destination: Text("Destination"))
////        {
////          Text("Navigate")
////        }
////        }
//      })
      
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
