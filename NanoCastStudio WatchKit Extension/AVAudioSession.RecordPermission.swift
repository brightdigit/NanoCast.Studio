import AVFoundation

extension AVAudioSession.RecordPermission : CustomStringConvertible {
  public var description: String {
    switch self {
    case .denied:
      return "denied"
    case .granted:
      return "granted"
    default:
      return "IDK"
    }
  }
}
