//
//  TitleNode.swift
//  ShakuroApp
//
//  Created by o on 16.09.2020.
//  Copyright © 2020 Shakuro. All rights reserved.
//

import SpriteKit

final class LabelEffectNode: SKNode {

    private enum Constant {
        static let warpXStep: Float = 1.0 / 50.0
        static let warpYStep: Float = 1.0 / 4.0
        static let amplitude: Float = 0.07
        static let period: Float = 10

        static let transitionDuration: Double = 0.4
    }

    private(set) var text: String = ""

    var font: UIFont = UIFont.systemFont(ofSize: 10) {
        didSet {
            warpNode?.labelNode.fontName = font.fontName
            warpNode?.labelNode.fontSize = font.pointSize
        }
    }

    var color: UIColor? = UIColor(hex: "#FC5185") {
        didSet {
            warpNode?.labelNode.fontColor = color
        }
    }

    private var warpNode: WarpNode?

    private lazy var warpGrid: WarpGrid = {
        let rows: [Float] = Array(stride(from: 0, through: 1, by: Constant.warpXStep)).reversed()
        let columns: [Float] = Array(stride(from: 0, through: 1, by: Constant.warpYStep))
        var source: [SIMD2<Float>] = []
        var dest: [SIMD2<Float>] = []
        rows.forEach { (rowValue) in
            columns.forEach { (value) in
                source.append(SIMD2<Float>(value, rowValue))
                dest.append(SIMD2<Float>(value + Constant.amplitude * sin(rowValue * Constant.period), rowValue))
            }
        }
        return WarpGrid(rows: rows.count, columns: columns.count, source: source, destination: dest)
    }()

    func setText(_ newText: String, animated: Bool) {

        let duration: Double = Constant.transitionDuration
        let newNode = WarpNode(font: font, text: newText, color: color)
        newNode.warpGeometry = warpGrid.noWarpGeometry
        newNode.alpha = 0

        let showNewNode = {
            if animated, let action = SKAction.warp(to: self.warpGrid.noWarpGeometry, duration: duration) {
                newNode.position = CGPoint(x: 130, y: 0)
                newNode.warpGeometry = self.warpGrid.warpGeometry
                let moveAction = SKAction.moveBy(x: -130, y: 0, duration: duration)
                moveAction.timingMode = .easeOut
                action.timingMode = .easeOut
                newNode.run(SKAction.group([moveAction, action, SKAction.fadeIn(withDuration: duration)]))
            } else {
                newNode.alpha = 1
            }
        }
        addChild(newNode)

        if let oldNode = warpNode {
            if animated, let action = SKAction.warp(to: warpGrid.warpGeometry, duration: duration) {
                let moveAction = SKAction.moveBy(x: -120, y: 0, duration: duration)
                moveAction.timingMode = .easeIn
                action.timingMode = .easeIn
                oldNode.run(SKAction.sequence([SKAction.group([moveAction, action, SKAction.fadeOut(withDuration: duration)]), SKAction.run { [weak oldNode] in
                    showNewNode()
                    oldNode?.removeFromParent()
                    }]))
            } else {
                showNewNode()
                oldNode.removeFromParent()
            }
            warpNode = nil
        } else {
            showNewNode()
        }
        warpNode = newNode
    }
}

private final class WarpNode: SKEffectNode {

    let labelNode = SKLabelNode()

    init (font: UIFont, text: String, color: UIColor?) {
        super.init()
        setup(font: font, text: text, color: color)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup(font: UIFont.systemFont(ofSize: 10), text: "", color: nil)
    }

    private func setup(font: UIFont, text: String, color: UIColor?) {
        labelNode.text = text
        labelNode.fontName = font.fontName
        labelNode.fontSize = font.pointSize
        labelNode.fontColor = color
        addChild(labelNode)
    }
}

private struct WarpGrid {
    let rows: Int
    let columns: Int

    let source: [SIMD2<Float>]
    let destination: [SIMD2<Float>]

    let warpGeometry: SKWarpGeometryGrid
    let noWarpGeometry: SKWarpGeometryGrid

    init(rows: Int, columns: Int, source: [SIMD2<Float>], destination: [SIMD2<Float>]) {
        self.rows = rows
        self.columns = columns
        self.source = source
        self.destination = destination
        warpGeometry = SKWarpGeometryGrid(columns: columns - 1,
                                          rows: rows - 1,
                                          sourcePositions: source,
                                          destinationPositions: destination)
        noWarpGeometry = SKWarpGeometryGrid(columns: columns - 1,
                                            rows: rows - 1,
                                            sourcePositions: source,
                                            destinationPositions: source)

    }
}
