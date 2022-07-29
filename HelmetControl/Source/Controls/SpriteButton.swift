//
//  SpriteButton.swift
//  ShakuroApp
//
//  Created by o on 17.08.2020.
//  Copyright © 2020 Shakuro. All rights reserved.
//

import SpriteKit

final class IndicatorNode: SKNode {

    var nodeColor: UIColor {
        get {
            return shapeNode.fillColor
        }
        set {
            shapeNode.strokeColor = newValue
            shapeNode.fillColor = newValue
        }
    }

    private let shapeNode: SKShapeNode

    init(_ color: UIColor?, radius: CGFloat) {
        self.shapeNode = SKShapeNode(circleOfRadius: radius)
        super.init()
        shapeNode.strokeColor = color ?? .clear
        shapeNode.lineWidth = 4
        shapeNode.fillColor = .clear
        addChild(shapeNode)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func moveTo(point: CGPoint, animated: Bool) {
        let action = SKAction.move(to: point, duration: animated ? 0.3 : 0.0)
        action.timingMode = .easeOut
        run(action)
    }
}

final class CircleShapeButton: SKNode {

    /// Called when the button is pressed.
    var action: (() -> Void)?

    /// Updates the appearance on button tap.
    var isSelected: Bool = false {
        didSet {
            if isSelected != oldValue {
                updateAppearance()
            }
        }
    }

    private let innerShape: SKShapeNode
    private let outerShape: SKShapeNode

    init(_ color: UIColor?, innerRadius: CGFloat, outerRadius: CGFloat) {
        let nodeColor = color ?? .clear
        self.innerShape = SKShapeNode(circleOfRadius: innerRadius)
        self.outerShape = SKShapeNode(circleOfRadius: outerRadius)
        super.init()
        innerShape.fillColor = nodeColor
        innerShape.strokeColor = nodeColor
        outerShape.fillColor = .clear
        outerShape.strokeColor = .clear
        addChild(innerShape)
        addChild(outerShape)
        updateAppearance()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        alpha = 0.8
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        alpha = 1.0
        action?()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        alpha = 1.0
    }

    private func updateAppearance(animated: Bool = false) {
        if isSelected {

        } else {

        }
    }

}
