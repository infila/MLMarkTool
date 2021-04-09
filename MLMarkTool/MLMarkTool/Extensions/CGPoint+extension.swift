//
//  CGPoint+extension.swift
//  MLMarkTool
//
//  Created by James Chen on 2019/10/31.
//  Copyright © 2019 JamesChen. All rights reserved.
//

import Foundation

extension CGPoint {
  
  func transform(byRotation radian:CGFloat, andScale scale:CGFloat) -> CGPoint {
    let adjustRadian = -radian
    let transform = CGAffineTransform(rotationAngle: adjustRadian).scaledBy(x: scale, y: scale)
    return self.applying(transform)
  }
  
  func offset(x: CGFloat, y: CGFloat) -> CGPoint {
    return CGPoint(x: self.x + x, y: self.y + y)
  }
}
