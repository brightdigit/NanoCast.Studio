//
//  ExtensionDelegate.swift
//  NanoCastStudio WatchKit Extension
//
//  Created by Leo Dion on 8/18/20.
//

import WatchKit
import CloudKit
import NCSKit
import UserNotifications


struct BundledConfiguration : Configuration {
  
  let bundle : Bundle
  
  var encryptionKey: Data {
    
    guard let url = bundle.url(forResource: "encriptionkey", withExtension: nil) else {
      preconditionFailure("Missing encriptionkey file")
    }
    
    
    return try! Data(contentsOf: url)
  }
  
  
}

extension Result  {
  func backgroundFetchResult<Key, Value>() -> WKBackgroundFetchResult where Success == Dictionary<Key,Value>   {
    switch (self, try? self.get().isEmpty) {
    case (.failure, _): return .failed
    case (.success, false): return .newData
    default: return .noData
    }
    
  }
}
class ExtensionDelegate: NSObject, WKExtensionDelegate, UNUserNotificationCenterDelegate {
  
  public var object : NCSObject!
//  public let keychainService = KeychainService(encryptionKey: (ProcessInfo.processInfo.environment["ENCRYPTION_KEY"]?.data(using: .utf8))!)

  func didReceiveRemoteNotification(_ userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (WKBackgroundFetchResult) -> Void) {
    print("received ntoification")
    dump(userInfo)
    guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
      return
    }
    
    guard notification.subscriptionID == "accountSubscriptionIDv1" else {
      return
    }
    dump(notification)
    object.refresh{
      
      completionHandler($0.backgroundFetchResult())
    }
  }
  func didFailToRegisterForRemoteNotificationsWithError(_ error: Error) {
    print(error)
  }
  
  func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
    print("deviceToken", deviceToken.base64EncodedString())
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    dump(notification)
    
  }
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
      UNUserNotificationCenter.current().delegate = self
      UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
        debugPrint(granted)
        dump(error)
      }
      self.object = NCSObject(configuration: BundledConfiguration(bundle: .main))
      WKExtension.shared().registerForRemoteNotifications()
      self.object.beginSubscription()
      print("finishing launch")
    }

    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            case let relevantShortcutTask as WKRelevantShortcutRefreshBackgroundTask:
                // Be sure to complete the relevant-shortcut task once you're done.
                relevantShortcutTask.setTaskCompletedWithSnapshot(false)
            case let intentDidRunTask as WKIntentDidRunRefreshBackgroundTask:
                // Be sure to complete the intent-did-run task once you're done.
                intentDidRunTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
