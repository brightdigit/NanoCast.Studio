//
//  LoginView.swift
//  NanoCastStudio WatchKit Extension
//
//  Created by Leo Dion on 8/19/20.
//

import SwiftUI
import NCSKit

struct LoginView: View {
  @EnvironmentObject var application : NCSObject
  var statusImage : some View {
    Group {
      
      self.application.userResult.map {
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
        TextField("API Key", text: $application.loginApiKey)
        Button("Sign in") {
          self.application.signIn()
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
