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
  public init (encryptionKey: Data) {
    self.defaults = UserDefaults(suiteName: "group.com.brightdigit.NanoCastStudio")!
    let container = CKContainer(identifier: "iCloud.com.brightdigit.NanoCastStudio")
    self.encryptionKey = encryptionKey
    self.database = container.privateCloudDatabase
    let database = container.privateCloudDatabase
    //    subscription.subscriptionID = "accountSubscriptionID"
    let subscriptionId = "accountSubscriptionIDv1"
    
    //
    //    let accountSubscriptionID = defaults?.string(forKey: "accountSubscriptionID")
    // TODO: Use CKModifySubscriptionsOperation
    
    self.database.fetchAllSubscriptions { (subscriptions, error) in
      let result = Result(failure: error, success: subscriptions, else: EmptyError.init)
      let foundResult = result.map{ (subscriptions) -> (CKSubscription?, [CKSubscription.ID]) in
        var found : CKSubscription?
        var ids = [CKSubscription.ID]()
        for subscription in subscriptions {
          if found == nil, subscription.subscriptionID == subscriptionId {
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
      let group = DispatchGroup()
      let queue = DispatchQueue(label: "cloud")
      let resultqueue = DispatchQueue(label: "result", attributes: .concurrent)
      var results = [Result<Void, Error>]()
      ids.forEach { (id) in
        group.enter()
        queue.async {
          container.privateCloudDatabase.delete(withSubscriptionID: id) { _ , error in
            let result = Result(failure: error, success: (), else: EmptyError.init).map{_ in ()}
            resultqueue.async(flags: .barrier) {
              
              results.append(result)
              group.leave()
            }
          }
        }
      }
      if subscription == nil {
        group.enter()
        let subscription = CKQuerySubscription(recordType: "Account", predicate: .init(value: true), subscriptionID: subscriptionId, options: [.firesOnRecordUpdate, .firesOnRecordUpdate])
        subscription.notificationInfo = .init(shouldBadge: false, shouldSendContentAvailable: true)
        database.save(subscription) { (_, error) in
          let result = Result(failure: error, success: (), else: EmptyError.init).map{_ in ()}
          resultqueue.async(flags: .barrier) {
            
            results.append(result)
            group.leave()
          }
        }
      }
      group.notify(queue: queue){
        print(results)
      }
    }
    
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
        print(data.count)
        let actualData = Data(data[0...(data.count-17)])
        let iv = Data(data.suffix(16))
        
        print(String(data: iv, encoding: .utf8))
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
    //    if let data = dictionary[key] {
    //      let actualData = data[0...(data.count-17)]
    //      let iv = Data(data.suffix(16))
    //      print(String(data: iv, encoding: .utf8))
    //      print("Decypting \(actualData.count) bytes")
    //      let aes = try AES(key: self.key.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)
    //      if let text = String(data: try actualData.decrypt(cipher: aes), encoding: .utf8) {
    //        return text
    //      }
    //    }
    //    return nil
    //    let queryLoad: [String: AnyObject] = [
    //      kSecClass as String: kSecClassGenericPassword,
    //      kSecAttrAccount as String: key as AnyObject,
    //      kSecReturnData as String: kCFBooleanTrue,
    //      kSecMatchLimit as String: kSecMatchLimitOne,
    //      kSecAttrAccessGroup as String: self.groupName as AnyObject,
    //      kSecAttrSynchronizable as String: kCFBooleanTrue
    //    ]
    //
    //    var result: AnyObject?
    //
    //    let resultCodeLoad = withUnsafeMutablePointer(to: &result) {
    //      SecItemCopyMatching(queryLoad as CFDictionary, UnsafeMutablePointer($0))
    //    }
    //
    //
    //
    //    if resultCodeLoad == noErr {
    //      if let result = result as? Data {
    //        return String(data: result, encoding: .utf8)
    //      }
    //      preconditionFailure()
    //    } else if resultCodeLoad == errSecItemNotFound {
    //      return nil
    //    } else {
    //      throw SecError(code: resultCodeLoad)
    //    }
  }
  
  func saveKey(_ value: String, _ callback: @escaping ((Error?) -> Void) ) {
    defaults.setValue(value, forKey: "TRANSISTORFM_API_KEY")
    let actualData = value.data(using: .utf8)!
    let ivChars = "1234567890123456".shuffled()
    let ivString = String(ivChars)
    let ivData = ivString.data(using: .utf8)!
    print(actualData.count)
    print(ivData.count)
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
    //    let actualData = value.data(using: .utf8)!
    //    let ivChars = "1234567890123456".shuffled()
    //    let ivString = String(ivChars)
    //    let ivData = ivString.data(using: .utf8)!
    //    print(ivString)
    //    let data = actualData + ivData
    //    let aes = try AES(key: self.key.bytes, blockMode: CBC(iv: ivData.bytes), padding: .pkcs7)
    //    let encrypted = try actualData.encrypt(cipher: aes)
    //    print("Encypted \(encrypted.count)")
    //    self.dictionary[key] = encrypted + ivData
    //try keychain.set(value, key: key)
    //Keychain(accessGroup: "MLT7M394S7.com.brightdigit.NanoCastStudio").synchronizable(true)[key] = value
    //    guard let valueData = value.data(using: String.Encoding.utf8) else {
    //      print("Error saving text to Keychain")
    //      return
    //    }
    //
    //    let queryAdd: [String: AnyObject] = [
    //      kSecClass as String: kSecClassGenericPassword,
    //      kSecAttrAccount as String: key as AnyObject,
    //      kSecValueData as String: valueData as AnyObject,
    //      kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
    //      kSecAttrAccessGroup as String: self.groupName as AnyObject
    //    ]
    //
    //    let resultCode = SecItemAdd(queryAdd as CFDictionary, nil)
    //
    //    if resultCode != noErr {
    //      throw SecError(code: resultCode)
    //    }
  }
}
