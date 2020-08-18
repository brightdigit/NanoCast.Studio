//
//  ContentView.swift
//  NanoCast.Studio WatchKit Extension
//
//  Created by Leo Dion on 8/18/20.
//

import SwiftUI

struct VolumeView: WKInterfaceObjectRepresentable {
    typealias WKInterfaceObjectType = WKInterfaceVolumeControl


    func makeWKInterfaceObject(context: Self.Context) -> WKInterfaceVolumeControl {
        let view = WKInterfaceVolumeControl(origin: .local)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak view] timer in
            if let view = view {
                view.focus()
            } else {
                timer.invalidate()
            }
        }
        DispatchQueue.main.async {
            view.focus()
        }
        return view
    }
    func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceVolumeControl, context: WKInterfaceObjectRepresentableContext<VolumeView>) {
    }
}

struct ContentView: View {
  @EnvironmentObject var sessionObject : RecordingSessionObject
  
    var body: some View {
      VStack {
        VolumeView().opacity(1)
        Text("\(self.sessionObject.currentTime)")
        Button("Grant Permission") {
          self.sessionObject.prepare()
        }
//        Text("\(sessionObject.error?.localizedDescription ?? "no error")")
//        Text("\((sessionObject.isReady ? "Ready" : "Not Ready"))")
//        Text("\(sessionObject.permission.description)")
//        Text("\(String(sessionObject.category.rawValue.suffix(10)))")
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
