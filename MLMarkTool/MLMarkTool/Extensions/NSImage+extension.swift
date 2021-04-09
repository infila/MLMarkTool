//
//  NSImage+extension.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/25.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Cocoa

extension NSImage {
  public func draw(image: NSImage,
                   atCenterPoint centerPoint: CGPoint,
                   withScale scale: CGFloat,
                   alpha: CGFloat,
                   andRotation rotation: CGFloat) -> NSImage {
    let transformedImage = image.imageRotatedByRadians(radians: rotation)
    let x = centerPoint.x - transformedImage.size.width * scale / 2
    let y = centerPoint.y - transformedImage.size.height * scale / 2
    let resultImage = NSImage(size: pixelSize, flipped: false) { (imageRect) -> Bool in
      self.draw(in: imageRect)
      let macOsY = imageRect.height - (y + transformedImage.size.height * scale)
      let rect = NSRect(x: x, y: macOsY, width: transformedImage.size.width * scale, height: transformedImage.size.height * scale)
      transformedImage.draw(in: rect, from: NSRect.zero, operation: .sourceOver, fraction: alpha)
      return true
    }
    return resultImage
  }

  public func imageRotatedByRadians(radians: CGFloat) -> NSImage {
    var imageBounds = NSZeroRect; imageBounds.size = size
    let pathBounds = NSBezierPath(rect: imageBounds)
    var transform = NSAffineTransform()
    transform.rotate(byRadians: radians)
    pathBounds.transform(using: transform as AffineTransform)
    let rotatedBounds: NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y, pathBounds.bounds.size.width, pathBounds.bounds.size.height)
    let rotatedImage = NSImage(size: rotatedBounds.size)

    // Center the image within the rotated bounds
    imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
    imageBounds.origin.y = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)

    // Start a new transform
    transform = NSAffineTransform()
    // Move coordinate system to the center (since we want to rotate around the center)
    transform.translateX(by: +(NSWidth(rotatedBounds) / 2), yBy: +(NSHeight(rotatedBounds) / 2))
    transform.rotate(byRadians: radians)
    // Move the coordinate system bak to normal
    transform.translateX(by: -(NSWidth(rotatedBounds) / 2), yBy: -(NSHeight(rotatedBounds) / 2))
    // Draw the original image, rotated, into the new image
    rotatedImage.lockFocus()
    transform.concat()
    draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
    rotatedImage.unlockFocus()

    return rotatedImage
  }

  var pngData: Data? {
    guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
    return bitmapImage.representation(using: .png, properties: [:])
  }

  var pixelSize: CGSize {
    guard representations.count > 0,
          representations[0].pixelsWide != 0 && representations[0].pixelsHigh != 0 else {
      return size
    }
    return CGSize(width: representations[0].pixelsWide, height: representations[0].pixelsHigh)
  }

  func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
    do {
      try pngData?.write(to: url, options: options)
      return true
    } catch {
      print(error)
      return false
    }
  }
  
  var scale: CGFloat {
    guard pixelSize.width / size.width == pixelSize.height / size.height else {
      assert(false, "PixelSize:\(pixelSize) or Size:\(size) invalid")
      return 1
    }
    return pixelSize.width / size.width
  }
}
