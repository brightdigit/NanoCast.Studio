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

public protocol AccountProperties {
  init(fromDictionary dictionary: [String : String]) throws
  func asDictionary() -> [String : String]
}

public struct Account<PropertiesType : AccountProperties> {
  public let name : String
  public let properties : PropertiesType
  
  
}

extension Account {
  public static func transistorApiKey(_ key: String, withName name: String = "Transistor") -> Account<TransistorProperties> where PropertiesType == TransistorProperties {
    return Account<TransistorProperties>(name: name, properties: TransistorProperties(apiKey: key))
  }
}

public struct TransistorProperties : AccountProperties {
  init (apiKey : String) {
    self.apiKey = apiKey
  }
  public init(fromDictionary dictionary: [String : String]) throws {
    self.apiKey = dictionary["apiKey"] ?? ""
  }
  
  public func asDictionary() -> [String : String] {
    return ["apiKey" : apiKey]
  }
  
  let apiKey : String
}

public struct AnyAccount : Codable {
  public let name : String
  public let propertyData : [String : String]
  
  public init<PropertiesType>(account: Account<PropertiesType>) {
    self.name = account.name
    self.propertyData = account.properties.asDictionary()
  }
}

public typealias AccountCollection = [ UUID : AnyAccount ]

public struct AccountService {
  
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
    defaults.register(defaults: ["Accounts" : AccountCollection()])
    let container = CKContainer(identifier: "iCloud.com.brightdigit.NanoCastStudio")
    self.encryptionKey = encryptionKey
    self.database = container.privateCloudDatabase
  }
  
  func refresh(_ callback: @escaping ((Result<AccountCollection, Error>) -> Void)) {
    let query = CKQuery(recordType: "Account", predicate: .init(value: true))
    self.database.perform(query, inZoneWith: nil) { (records, error) in
      let result = Result(failure: error, success: records, else: EmptyError.init)
      let apiKeyResult = result.flatMap { (records) -> Result<AccountCollection, Error> in
        let decoder = JSONDecoder()
        
        let pairs = records.map { (record) -> Result<(UUID,AnyAccount),Error> in
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
          let account : AnyAccount
        do {
          aes = try AES(key: self.encryptionKey.bytes, blockMode: CBC(iv: iv.bytes), padding: .pkcs7)
          
          guard let decrypted = try Data(base64Encoded: actualData.decrypt(cipher: aes)) else {
            return .failure(EmptyError())
          }
          descrypted = decrypted
          account = try decoder.decode(AnyAccount.self, from: descrypted)
        } catch {
          return .failure(error)
        }
          let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
          return .success((id,account))
        }
        return pairs.flatten().map(Dictionary.init(uniqueKeysWithValues:))
//
//        guard let text = String(data: descrypted, encoding: .utf8) else {
//          return .failure(EmptyError())
//        }
      
        //defaults.setValue(text, forKey: "TRANSISTORFM_API_KEY")
        //return .success(text)
      }
      if case let .success(accounts) = apiKeyResult {
        defaults.setValue(accounts, forKey: "Accounts")
      }
      callback(apiKeyResult)
    }
  }
  
  func fetchKey(_ callback: @escaping ((Result<AccountCollection, Error>) -> Void)) {
    let decoder = JSONDecoder()
    if let key = defaults.data(forKey: "Accounts").flatMap{ try? decoder.decode(AccountCollection.self, from: $0) } {
      if !key.isEmpty {
      callback(.success(key))
        return
      }
    }
    refresh(callback)
  }
  
  func save<PropertiesType>(_ account: Account<PropertiesType>, _ callback: @escaping ((Error?) -> Void) ) {
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    let anyAccount = AnyAccount(account: account)
    let id = UUID()
    var accounts = defaults.data(forKey: "Accounts").flatMap{ try? decoder.decode(AccountCollection.self, from: $0) } ?? AccountCollection()
    //var accounts = defaults.value(forKey: "Accounts") as? AccountCollection ?? AccountCollection()
    accounts[id] = anyAccount
    if let data = try? encoder.encode(accounts) {
      defaults.set(data, forKey: "Accounts")
    }
    let actualData : Data
    do {
      actualData = try encoder.encode(anyAccount).base64EncodedData()
    } catch {
      return callback(error)
    }
    
//    let ivChars = "1234567890123456".shuffled()
//    let ivString = String(ivChars)
    let ivData = AES.randomIV(16)
    let aes : AES
    let encrypted : Data
    do {
      aes = try AES(key: self.encryptionKey.bytes, blockMode: CBC(iv: ivData), padding: .pkcs7)
      encrypted = try actualData.encrypt(cipher: aes)
    } catch {
      callback(error)
      return
    }
    let record = CKRecord(recordType: "Account", recordID: .init(recordName: id.uuidString))
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
