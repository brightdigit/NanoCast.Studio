import Foundation
import S3
import NIO

public struct S3Service {
  let bucket: String
  let s3 : S3
  
  public init (accessKeyId: String?, secretAccessKey: String?, region: Region?, bucket: String) {
    s3 = S3(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey, region: region)
    self.bucket = bucket
  }
  
  public func uploadData(_ data : Data, with key: String) -> EventLoopFuture<URL> {
    let putObjectRequest = S3.PutObjectRequest(acl: .publicRead, body: data, bucket: bucket, contentLength: Int64(data.count), expires: TimeStamp(Date(timeIntervalSinceNow: 60 * 60 * 24)), key: key)
    
    let result = s3.putObject(putObjectRequest)
    return result.map { (output) in
      return URL(string: "https://\(bucket).s3-us-west-2.amazonaws.com/\(key)")!
    }

  }
  
  public func delete(key : String) -> EventLoopFuture<Void> {
    let request = S3.DeleteObjectRequest(bucket: bucket, key: key)
    return s3.deleteObject(request).map{_ in ()}
  }
  
}
