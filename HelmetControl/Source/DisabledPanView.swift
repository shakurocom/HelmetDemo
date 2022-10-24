//
//  DisabledPanView.swift
//  ShakuroApp
//
//  Created by Vlad Onipchenko on 8/25/20.
//  Copyright © 2020 Shakuro. All rights reserved.
//

import SpriteKit

class DisabledPanView: UIView {

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !(gestureRecognizer is UIPanGestureRecognizer)
    }

}

class DisabledPanSKView: SKView {

  override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return !(gestureRecognizer is UIPanGestureRecognizer)
    }

}
