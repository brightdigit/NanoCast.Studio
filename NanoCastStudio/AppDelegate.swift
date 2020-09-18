//
//  AppDelegate.swift
//  NanoCastStudio
//
//  Created by Leo Dion on 8/18/20.
//

import UIKit
import NCSKit
import CloudKit

struct BundledConfiguration : Configuration {
  
  let bundle : Bundle
  
  var encryptionKey: Data {
    
    guard let url = bundle.url(forResource: "encryptionkey", withExtension: nil) else {
      preconditionFailure("Missing encriptionkey file")
    }
    
    
    return try! Data(contentsOf: url)
  }
  
  
}

extension Result  {
  func backgroundFetchResult<Key, Value>() -> UIBackgroundFetchResult where Success == Dictionary<Key,Value>   {
    switch (self, try? self.get().isEmpty) {
    case (.failure, _): return .failed
    case (.success, false): return .newData
    default: return .noData
    }
    
  }
}
@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  
  public var object : NCSObject!
  //public let keychainService = KeychainService(encryptionKey: (ProcessInfo.processInfo.environment["ENCRYPTION_KEY"]?.data(using: .utf8))!)

  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    
      guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else {
        return
      }
      
      guard notification.subscriptionID == "accountSubscriptionIDv1" else {
        return
      }
    
    object.refresh { (result) in
//      let fetchResult : UIBackgroundFetchResult
//      switch result {
//      case .failure: fetchResult = .failed
//      case .success(.none): fetchResult = .noData
//      case .success(.some): fetchResult = .newData
//      }
      completionHandler(result.backgroundFetchResult())
    }
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print(error)
    
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("deviceToken", deviceToken.base64EncodedString())
  }

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
//    UNUserNotificationCenter.current().delegate = self
//    UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
//      debugPrint(granted)
//      dump(error)
//    }
    application.registerForRemoteNotifications()
    print("finishing launch")
    self.object = NCSObject(configuration: BundledConfiguration(bundle: .main))
    self.object.beginSubscription()
    return true
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }


}

