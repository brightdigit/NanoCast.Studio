//
//  HostingController.swift
//  NanoCast.Studio WatchKit Extension
//
//  Created by Leo Dion on 8/18/20.
//

import WatchKit
import Foundation
import SwiftUI
import NCSKit

class HostingController: WKHostingController<AnyView> {
    override var body: AnyView {
      return
        AnyView(ContentView().environmentObject(NCSObject()))
    }
}
