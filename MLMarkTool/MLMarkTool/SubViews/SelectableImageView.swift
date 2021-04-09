//
//  SelectableImageView.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/15.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

class SelectableImageView: NSImageView {
  
  var selectable: Bool = true
  var onRectSelected: ((CGRect)->())?
  
  var imageScale: CGFloat {
    guard let image = image else { return -1 }
    let rep: NSImageRep = image.representations[0]
    let width = rep.pixelsWide != 0 ? CGFloat(rep.pixelsWide) : rep.size.width
    let height = rep.pixelsHigh != 0 ? CGFloat(rep.pixelsHigh) : rep.size.height
    let scale = min((self.width / width), (self.height / height))
    return scale
  }

  private var beginPoint: CGPoint?
  private var endPoint: CGPoint?
  
  override func draw(_ dirtyRect: NSRect) {
    super.draw(dirtyRect)
    
    guard let beginPoint = beginPoint, let endPoint = endPoint else {
      return
    }
    let rect = CGRect.make(start: beginPoint, end: endPoint, minSize: 0.1)
    NSColor.blue.set()
    let path = NSBezierPath(rect:rect)
    path.lineWidth = 2
    path.stroke()
  }
  
  override func mouseDown(with event: NSEvent) {
    super.mouseDown(with: event)
    if event.type != .leftMouseDown || !selectable {
      return
    }
    beginPoint = convert(event.locationInWindow, from: nil)
  }
  
  override func mouseDragged(with event: NSEvent) {
    super.mouseDragged(with: event)
    if event.type != .leftMouseDragged || !selectable {
      return
    }
    let endPoint = convert(event.locationInWindow, from: nil)
    guard let beginPoint = beginPoint else {
      return
    }
    if abs(endPoint.x - beginPoint.x) < 5 && abs(endPoint.y - beginPoint.y) < 5 {
      return
    }
    self.endPoint = endPoint
    display()
  }
  
  override func mouseUp(with event: NSEvent) {
    super.mouseUp(with: event)
    if event.type != .leftMouseUp || !selectable {
      return
    }
    guard let beginPoint = beginPoint, let endPoint = endPoint else {
      return
    }
    self.beginPoint = nil
    self.endPoint = nil
    let rect = CGRect.make(start: beginPoint, end: endPoint, minSize: 0.1)
    onRectSelected?(rect)
  }
  
//  private func roundingPoint(_ point: CGPoint) -> CGPoint {
//    return CGPoint(x: lrintf(Float(point.x)), y: lrintf(Float(point.y)))
//  }
}

extension CGRect {
  public static func make(start: CGPoint, end: CGPoint, minSize: CGFloat) -> CGRect {
    if start == end {
      return CGRect.zero
    }
    let originPoint = CGPoint(x: min(start.x, end.x), y: min(start.y, end.y))
    let size = CGSize(width: max(abs(start.x - end.x), minSize), height: max(abs(start.y - end.y), minSize))
    return CGRect(origin: originPoint, size: size)
  }
}
