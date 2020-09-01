import Foundation
import CryptoSwift
import CloudKit
import UserNotifications

extension Array {
  func flatten<Success, Failure>() -> Result<[Success], Failure> where Element == Result<Success, Failure> {
    var successes = [Success]()
    for result in self {
      switch result {
      case .failure(let error):
        return .failure(error)
      case .success(let success):
        successes.append(success)
      }
    }
    return .success(successes)
  }
}
public struct  KeychainService {
  
  let encryptionKey : Data
  //var currentError : Error?
  public let defaults : UserDefaults
  let database : CKDatabase
  
  public func beginSubscription () {
    let clearAllSubscriptions = ProcessInfo.processInfo.environment["CLEAR_ALL_SUBSCRIPTIONS"].map{ Bool($0) ?? true} ?? false
    
    if clearAllSubscriptions {
      print("Clearing all subscriptions...")
    }
    let subscriptionId = "accountSubscriptionIDv1"
    self.database.fetchAllSubscriptions { (subscriptions, error) in
      let result = Result(failure: error, success: subscriptions, else: EmptyError.init)
      let foundResult = result.map{ (subscriptions) -> (CKSubscription?, [CKSubscription.ID]) in
        var found : CKSubscription?
        var ids = [CKSubscription.ID]()
        for subscription in subscriptions {
          if found == nil, subscription.subscriptionID == subscriptionId, !clearAllSubscriptions {
            found = subscription
          } else {
            ids.append(subscription.subscriptionID)
          }
        }
        return (found, ids)
      }
      let subscription : CKSubscription?
      let ids : [CKSubscription.ID]
      do {
        (subscription, ids) = try foundResult.get()
      } catch {
        //self.currentError = error
        return
      }
      let subscriptionsToSave : [CKSubscription]?
      if subscription == nil, !clearAllSubscriptions {
        //group.enter()
        let subscription = CKQuerySubscription(recordType: "Account", predicate: .init(value: true), subscriptionID: subscriptionId, options: [.firesOnRecordUpdate, .firesOnRecordCreation])
        subscription.notificationInfo = .init(alertBody: "Received API Key", shouldBadge: false, shouldSendContentAvailable: true)
        subscriptionsToSave = [subscription]
      } else {
        subscriptionsToSave = nil
        guard !ids.isEmpty else {
          print("no subscription changes")
          return
        }
      }
      
      let modifySubscriptionsOp = CKModifySubscriptionsOperation(subscriptionsToSave: subscriptionsToSave, subscriptionIDsToDelete: ids.isEmpty ? nil : ids)
      
      modifySubscriptionsOp.modifySubscriptionsCompletionBlock = {
        print("modificaiton complete", $2)
      }
      modifySubscriptionsOp.completionBlock = {
        print("block complete")
      }
      modifySubscriptionsOp.qualityOfService = .userInteractive
      modifySubscriptionsOp.queuePriority = .veryHigh
      
      let container = CKContainer(identifier: "iCloud.com.brightdigit.NanoCastStudio")
      modifySubscriptionsOp.database = container.privateCloudDatabase
      container.privateCloudDatabase.add(modifySubscriptionsOp)
    }
  }
  
  public init (encryptionKey: Data) {
    self.defaults = UserDefaults(suiteName: "group.com.brightdigit.NanoCastStudio")!
    let container = CKContainer(identifier: "iCloud.com.brightdigit.NanoCastStudio")
    self.encryptionKey = encryptionKey
    self.database = container.privateCloudDatabase
    let database = container.privateCloudDatabase
  }
  
  public func refresh(_ callback: @escaping ((Result<String?, Error>) -> Void)) {
    let query = CKQuery(recordType: "Account", predicate: .init(value: true))
    self.database.perform(query, inZoneWith: nil) { (records, error) in
      let result = Result(failure: error, success: records, else: EmptyError.init)
      let apiKeyResult = result.flatMap { (records) -> Result<String?, Error> in
        guard let record = records.first else {
          return .success(nil)
        }
        
        guard records.count == 1 else {
          return .failure(EmptyError())
        }
        
        guard let data = record["Key"] as? Data else {
          return .failure(EmptyError())
        }
        
        guard data.count > 16 else {
          return .failure(EmptyError())
        }
        //print(data.count)
        let actualData = Data(data[0...(data.count-17)])
        let iv = Data(data.suffix(16))
        
        //print("iv", String(data: iv, encoding: .utf8))
        let aes : AES
        let descrypted : Data
        do {
          aes = try AES(key: self.encryptionKey.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)
          descrypted = try actualData.decrypt(cipher: aes)
          
        } catch {
          return .failure(error)
        }
        
        
        guard let text = String(data: descrypted, encoding: .utf8) else {
          return .failure(EmptyError())
        }
        defaults.setValue(text, forKey: "TRANSISTORFM_API_KEY")
        return .success(text)
      }
      
      
      callback(apiKeyResult)
    }
  }
  
  func fetchKey(_ callback: @escaping ((Result<String?, Error>) -> Void)) {
    if let key = defaults.string(forKey: "TRANSISTORFM_API_KEY") {
      callback(.success(key))
    }
    refresh(callback)
  }
  
  func saveKey(_ value: String, _ callback: @escaping ((Error?) -> Void) ) {
    defaults.setValue(value, forKey: "TRANSISTORFM_API_KEY")
    let actualData = value.data(using: .utf8)!
    let ivChars = "1234567890123456".shuffled()
    let ivString = String(ivChars)
    let ivData = ivString.data(using: .utf8)!
    let aes : AES
    let encrypted : Data
    do {
      aes = try AES(key: self.encryptionKey.bytes, blockMode: CBC(iv: ivData.bytes), padding: .pkcs7)
      encrypted = try actualData.encrypt(cipher: aes)
    } catch {
      callback(error)
      return
    }
    let record = CKRecord(recordType: "Account")
    record["Key"] = encrypted + ivData
    let query = CKQuery(recordType: "Account", predicate: .init(value: true))
    database.perform(query, inZoneWith: nil) { (records, error) in
      let result = Result(failure: error, success: records, else: EmptyError.init)
      let ids : [CKRecord.ID]
      do {
        ids = try result.get().map{$0.recordID}
      } catch {
        callback(error)
        return
      }
      let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: ids)
      
      operation.modifyRecordsCompletionBlock = { (_, _, error) in
        callback(error)
      }
      self.database.add(operation)
    }
  }
}
