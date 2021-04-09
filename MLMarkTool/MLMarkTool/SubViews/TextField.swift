//
//  TextField.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/15.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

class TextField: NSTextField {

  override var isEnabled: Bool {
    didSet {
      self.backgroundColor = self.isEnabled ? NSColor.white : NSColor.placeholderTextColor
    }
  }
  
}
