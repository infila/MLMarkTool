//
//  Dictionary+extension.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/23.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Foundation

extension Dictionary {
  public func element(at index: Int) -> Dictionary<Key, Value>.Element {
    return self[self.index(startIndex, offsetBy: index)]
  }

  public func first() -> Dictionary<Key, Value>.Element {
    return self[index(startIndex, offsetBy: 0)]
  }

  public func last() -> Dictionary<Key, Value>.Element {
    return self[index(endIndex, offsetBy: 0)]
  }
}

extension Dictionary.Keys {
  public subscript(index: Int) -> Element {
    return self[self.index(startIndex, offsetBy: index)]
  }

  public func first() -> Element {
    return self[index(startIndex, offsetBy: 0)]
  }

  public func last() -> Element {
    return self[index(endIndex, offsetBy: 0)]
  }
}

extension Dictionary.Values {
  public subscript(index: Int) -> Element {
    return self[self.index(startIndex, offsetBy: index)]
  }

  public func first() -> Element {
    return self[index(startIndex, offsetBy: 0)]
  }

  public func last() -> Element {
    return self[index(endIndex, offsetBy: 0)]
  }
}
