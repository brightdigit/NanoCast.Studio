//
//  ContentView.swift
//  NanoCastStudio WatchKit Extension
//
//  Created by Leo Dion on 8/19/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
      ZStack{
        LoginView()
      }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
