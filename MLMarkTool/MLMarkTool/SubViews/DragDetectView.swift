//
//  DragDetectView.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/14.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

let filteringOptions = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes:NSImage.imageTypes]

class DragDetectView: NSView {
  var onFileChoosed: (([URL])->())?
  
  private var isReceivingDrag = false {
    didSet {
      needsDisplay = true
    }
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
    registerForDraggedTypes([NSPasteboard.PasteboardType.URL])
  }
  
//  override func draw(_ dirtyRect: NSRect) {
//    super.draw(dirtyRect)
//    if isReceivingDrag {
//      NSColor.green.set()
//      
//      let path = NSBezierPath(rect:bounds)
//      path.lineWidth = 4
//      path.stroke()
//    }
//  }
  
  private func shouldAllowDrag(_ draggingInfo: NSDraggingInfo) -> Bool {
    var canAccept = false
    
    let pasteBoard = draggingInfo.draggingPasteboard
    
    if pasteBoard.canReadObject(forClasses: [NSURL.self], options: filteringOptions) {
      canAccept = true
    }
    return canAccept
  }
  
  override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
    return shouldAllowDrag(sender)
  }

  override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
    let allow = shouldAllowDrag(sender)
    isReceivingDrag = allow
    return allow ? .copy : NSDragOperation()
  }
  
  override func draggingExited(_ sender: NSDraggingInfo?) {
    isReceivingDrag = false
  }
  
  override func performDragOperation(_ draggingInfo: NSDraggingInfo) -> Bool {
    isReceivingDrag = false
    let pasteBoard = draggingInfo.draggingPasteboard
    if let urls = pasteBoard.readObjects(forClasses: [NSURL.self], options:filteringOptions) as? [URL], urls.count > 0 {
      onFileChoosed?(urls)
      return true
    }
    return false
  }
}

