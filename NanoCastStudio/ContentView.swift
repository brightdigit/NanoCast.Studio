//
//  ContentView.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/18/20.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var object : NCObject
    var body: some View {
      NavigationView(content: {
        VStack{
          TextField("API Key", text: $object.apiKey)
        NavigationLink(destination: Text("Destination"))
        {
          Text("Navigate")
        }
        }
      })
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
