
import Foundation

public struct SecError : Error, LocalizedError {
  public let code : OSStatus
  
  public init (code: OSStatus) {
    self.code = code
  }
  
  public var errorDescription: String? {
    return SecCopyErrorMessageString(self.code, nil) as String?
  }
}
