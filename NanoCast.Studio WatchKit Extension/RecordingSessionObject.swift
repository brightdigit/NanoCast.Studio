//
//  RecordingSessionObject.swift
//  NanoCast.Studio WatchKit Extension
//
//  Created by Leo Dion on 8/18/20.
//

import Foundation
import AVFoundation
import Combine

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

public class RecordingSessionObject: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
  @Published var error : Error?
  @Published var permission : AVAudioSession.RecordPermission
  @Published var category : AVAudioSession.Category
  @Published var isReady = false
  @Published var recoderResult : Result<AVAudioRecorder, Error>?
  @Published var playerResult : Result<AVAudioPlayer, Error>?
  
  var cancellables = [AnyCancellable]()
  
  var tempFileURL : URL
  
  static func nextAudioURL () -> URL {
    
    return  FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("m4a")
  }
  internal init(session: AVAudioSession) {
    self.session = session
    self.permission = session.recordPermission
    self.category = session.category
    self.tempFileURL = Self.nextAudioURL()
    
    super.init()
    let categoryPublisher = session.publisher(for: \.category)
    let permissionPublisher = session.publisher(for: \.recordPermission)
    
    let permissionPublisherMain = permissionPublisher.receive(on: DispatchQueue.main)
    
    let readyPublisher = categoryPublisher.combineLatest(permissionPublisher) { (category, permission) in
      return category == .playAndRecord && permission == .granted
    }.receive(on: DispatchQueue.main)
    
//    if #available(watchOSApplicationExtension 7.0, *) {
//      permissionPublisherMain.assign(to: &$permission)
//      readyPublisher.assign(to: &$isReady)
//      categoryPublisher.receive(on: DispatchQueue.main).assign(to: &$category)
//    } else {
      // Fallback on earlier versions
      permissionPublisherMain.sink {
        self.permission = $0
      }.store(in: &cancellables)
      
      categoryPublisher.receive(on: DispatchQueue.main).sink {
        self.category = $0
      }.store(in: &cancellables)
      
      readyPublisher.sink {
        self.isReady = $0
      }.store(in: &cancellables)
   // }
    
    
  }
  
  func prepare () {
    self.error = nil
    do {
      try self.session.setCategory(.playAndRecord, mode: .videoRecording, options: .init())
      try self.session.setActive(true)
    } catch {
      self.error = error
    }
    self.session.requestRecordPermission { (granted) in
      if granted {
        
      } else {
        
      }
    }
  }
  func record () {
    switch recoderResult {
    case .none:
      let settings = [
          AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
          AVSampleRateKey: 24000,
          AVNumberOfChannelsKey: 1,
          AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
      ]
      
      self.recoderResult = Result{
        let recorder = try AVAudioRecorder(url: tempFileURL, settings: settings)
        recorder.delegate = self
        recorder.record()
        return recorder
      }
    case .success(let recorder):
      recorder.stop()
      self.recoderResult = nil
    default:
      return
    }
  }
  
  func play () {
    
    if self.playerResult  == nil {
    let playerResult = Result{ () -> AVAudioPlayer in
      let player = try AVAudioPlayer(contentsOf: self.tempFileURL)
      player.delegate = self
      player.play()
      return player
    }
      self.playerResult = playerResult
      return
    }
    
    if case let .success(player) = self.playerResult {
      player.play()
    }
  }
  
  public func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
    print("recdone \(flag)")
  }
  
  public func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
    print("encoding \(error)")
  }
  
  public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    
      print("decoding \(error)")
  }
  
  public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    print("pladone \(flag)")
    
  }
  let session: AVAudioSession
}
