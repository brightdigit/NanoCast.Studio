//
//  LoginView.swift
//  NanoCastStudio WatchKit Extension
//
//  Created by Leo Dion on 8/19/20.
//

import SwiftUI


struct LoginView: View {
  @EnvironmentObject var transistor : TransistorObject
  var statusImage : some View {
    Group {
      self.transistor.userResult.map {
        switch $0 {
        case .success:
          return "checkmark"
        case .failure:
          return "exclamationmark"
        }
      }.map(Image.init(systemName:))
    }
  }
    var body: some View {
      VStack{
        TextField("API Key", text: $transistor.apiKey)
        Button("Sign in") {
          self.transistor.beginSignin()
        }
        self.statusImage
      }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
