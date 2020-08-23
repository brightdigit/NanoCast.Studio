

public extension Result {
  init (failure: Failure?, success: Success?, else: () -> Failure) {
    if let failure = failure {
      self = .failure(failure)
    } else if let success = success {
      self = .success(success)
    } else {
      self = .failure(`else`())
    }
  }
}

public extension Request {
  static var fields : [String : [String]]? {
    return AttributesType.fieldSet.map{
      [$0.resource : $0.fields]
    }
  }
}
