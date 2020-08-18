//
//  ContentView.swift
//  NanoCast.Studio WatchKit Extension
//
//  Created by Leo Dion on 8/18/20.
//

import SwiftUI



struct ContentView: View {
  @EnvironmentObject var sessionObject : RecordingSessionObject
  
    var body: some View {
      VStack {
        Button("Grant Permission") {
          self.sessionObject.prepare()
        }
        Text("\(sessionObject.error?.localizedDescription ?? "no error")")
        Text("\((sessionObject.isReady ? "Ready" : "Not Ready"))")
        Text("\(sessionObject.permission.description)")
        Text("\(String(sessionObject.category.rawValue.suffix(10)))")
        Button("Record") {
          self.sessionObject.record()
        }
        Button("Play") {
          self.sessionObject.play()
        }
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
