//
//  HostingController.swift
//  NanoCast.Studio WatchKit Extension
//
//  Created by Leo Dion on 8/18/20.
//

import WatchKit
import Foundation
import SwiftUI

class HostingController: WKHostingController<AnyView> {
    override var body: AnyView {
      return
        AnyView(RecodingView().environmentObject(RecordingSessionObject(session: .sharedInstance())))
    }
}
