//
//  NSView+extension.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/14.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

extension NSView {
  func removeSubviews() {
    for view in subviews {
      view.removeFromSuperview()
    }
  }

  var x: CGFloat {
    return frame.x
  }

  var y: CGFloat {
    return frame.y
  }

  var width: CGFloat {
    return frame.width
  }

  var height: CGFloat {
    return frame.height
  }
}

extension CGRect {
  var x: CGFloat {
    return origin.x
  }

  var y: CGFloat {
    return origin.y
  }

  var width: CGFloat {
    return size.width
  }

  var height: CGFloat {
    return size.height
  }

  func transform(byRotation rotation: CGFloat, scale: CGFloat) -> CGRect {
    let transform = CGAffineTransform(translationX: midX, y: midY)
      .rotated(by: rotation)
      .scaledBy(x: scale, y: scale)
      .translatedBy(x: -midX, y: -midY)
    let rect = applying(transform)
    return rect
  }
}
