


public enum Many<Element : Codable> : Collection, Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    
    switch self {
    case .single(let item): try container.encode(item)
    case .plural(let items): try container.encode(items)
    }
  }
  
  public typealias Index = Array<Element>.Index
     
  public var startIndex: Index { return self.asArray().startIndex }
  public var endIndex: Index { return self.asArray().endIndex }

      // Required subscript, based on a dictionary index
  public subscript(index: Index) -> Element {
        get { return self.asArray()[index] }
      }

      // Method that returns the next index when iterating
  public func index(after i: Index) -> Index {
        return self.asArray().index(after: i)
      }
  
  private func asArray () -> Array<Element> {
    switch self {
    case .single(let item): return [item]
    case .plural(let items): return items
    }
  }
  
  case single(Element)
  case plural([Element])
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    
    do {
      let element = try container.decode(Element.self)
      self = .single(element)
      return
    } catch {
      debugPrint(error)
    }
    self = try .plural(container.decode([Element].self))
    
  }
}
