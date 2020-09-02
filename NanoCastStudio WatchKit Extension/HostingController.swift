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
      let object = (WKExtension.shared().delegate as! ExtensionDelegate).object!
      return
        AnyView(ContentView().environmentObject(object))
    }
}
