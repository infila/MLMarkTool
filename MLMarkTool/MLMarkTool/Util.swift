//
//  Util.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/15.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

class Util {
  
  public static func showMessage(message: String) {
    let alert = NSAlert.init()
    alert.messageText = message
    alert.runModal()
  }
  
  public static func fileName(from url: URL) -> String {
    if !url.isFileURL {
      showMessage(message: "Url: " + url.absoluteString + "is invalid!")
      return ""
    }
    return url.lastPathComponent
  }
}
