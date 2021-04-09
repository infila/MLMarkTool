//
//  BorderRectView.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/15.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

class BorderRectView: NSView {
  var onClicked: ((BorderRectView)->())?
  var highLighted: Bool = true {
    didSet {
      display()
    }
  }
  var borderWidth: CGFloat = 4
  
  private var _tag = -1
  override var tag: Int {
    get {
      return _tag
    }
    set {
      _tag = newValue
    }
  }
  
  private var _frame: CGRect
  override var frame: NSRect {
    get {
      return CGRect(x: _frame.origin.x + borderWidth / 4,
                    y: _frame.origin.y + borderWidth / 4,
                    width: _frame.size.width - borderWidth / 2,
                    height: _frame.size.height - borderWidth / 2)
    }
    set {
      _frame = CGRect(x: newValue.origin.x - borderWidth / 4,
                      y: newValue.origin.y - borderWidth / 4,
                      width: newValue.size.width + borderWidth / 2,
                      height: newValue.size.height + borderWidth / 2)
      super.frame = _frame
    }
  }

  required init?(coder: NSCoder) {
    _frame = CGRect.zero
    super.init(coder: coder)
    setup()
  }
  
  override init(frame frameRect: NSRect) {
    _frame = CGRect.zero
    super.init(frame: CGRect(x: frameRect.origin.x - borderWidth / 4,
                             y: frameRect.origin.y - borderWidth / 4,
                             width: frameRect.size.width + borderWidth / 2,
                             height: frameRect.size.height + borderWidth / 2))
    setup()
  }
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)

    if highLighted {
      NSColor.blue.set()
    } else {
      NSColor.black.set()
    }
    let path = NSBezierPath(rect:dirtyRect)
    path.lineWidth = borderWidth
    path.stroke()
  }
  
  @objc private func didTapped() {
    onClicked?(self)
  }
  
  private func setup() {
    self.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(self.didTapped)))
  }
    
}
