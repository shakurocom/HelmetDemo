//
//  PriceLabel.swift
//  ShakuroApp
//
//  Created by o on 08.09.2020.
//  Copyright © 2020 Shakuro. All rights reserved.
//

import UIKit

final class PriceLabel: UIView {

    private(set) var text: String = ""

    var font: UIFont = UIFont.systemFont(ofSize: 10) {
        didSet {
            if oldValue != font {
                reload()
            }
        }
    }

    private var path: StringPath?
    private var layers: [CAShapeLayer] = []

    override var intrinsicContentSize: CGSize {
        return path?.path.bounds.size ?? .zero
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layers.forEach({ $0.frame = bounds })
    }

    func setText(_ newText: String, animated: Bool) {
        text = newText
        if animated {
            transitionTo(newText: newText)
        } else {
            reload()
        }
    }

    func reset() {
        layer.removeAllAnimations()
        layers.forEach({ $0.removeFromSuperlayer() })
        layers.removeAll()
        path = nil
        setNeedsLayout()
    }

    func reload() {
        reset()
        guard !text.isEmpty else {
            return
        }
        path = text.generatePath(font: font)
        setNeedsLayout()
        if let actualPath = path {
            actualPath.paths.forEach { (subPath) in
                let shapeLayer = createLayer(path: subPath)
                layers.append(shapeLayer)
                layer.addSublayer(shapeLayer)
            }
        }
    }

}

// MARK: - Private

private extension PriceLabel {

    private enum Constant {
        static let animationKey = "transition_animation"
    }

    func transitionTo(newText: String) {
        guard let newPath = newText.generatePath(font: font) else {
            reset()
            return
        }
        var toRemoveLayers = [CAShapeLayer]()
        let oldPaths = path?.paths ?? []
        var newLayers: [CAShapeLayer] = []

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        CATransaction.setCompletionBlock({
            toRemoveLayers.forEach({ $0.removeFromSuperlayer() })
        })
        var toRemoveBeginTime = CACurrentMediaTime()
        var toAddBeginTime = CACurrentMediaTime()
        let transitionDelay: CFTimeInterval = 0.15

        let removeLayer = { (_ toRemoveLayer: CAShapeLayer) in
            toRemoveLayers.append(toRemoveLayer)
            self.addAnimation(aLayer: toRemoveLayer, beginTime: toRemoveBeginTime, hidingAnimation: true)
            toRemoveBeginTime += transitionDelay
        }

        let addLayer = { (_ toAddLayer: CAShapeLayer) in
            self.addAnimation(aLayer: toAddLayer, beginTime: toAddBeginTime, hidingAnimation: false)
            self.layer.addSublayer(toAddLayer)
            newLayers.append(toAddLayer)
            toAddBeginTime += transitionDelay
        }

        (0..<oldPaths.count).forEach { (index) in
            if index > newPath.paths.count {
                removeLayer(layers[index])
            } else {
                if oldPaths[index].character != newPath.paths[index].character {
                    removeLayer(layers[index])
                    addLayer(createLayer(path: newPath.paths[index]))
                } else {
                    newLayers.append(layers[index])
                }
            }
        }

        if oldPaths.count < newPath.paths.count {
            newPath.paths[oldPaths.count..<newPath.paths.count].forEach { (path) in
                addLayer(createLayer(path: path))
            }
        }
        layers = newLayers
        path = newPath

        CATransaction.commit()

    }

    func addAnimation(aLayer: CALayer, beginTime: CFTimeInterval, hidingAnimation: Bool) {
        let opacityKeyPath = "opacity"
        let positionKeyPath = "position"

        let fromPosition: CGPoint
        let toPosition: CGPoint
        let fromOpacity: Float
        let toOpacity: Float
        if hidingAnimation {
            fromOpacity = ((aLayer.presentation()?.value(forKeyPath: opacityKeyPath) ?? aLayer.value(forKeyPath: opacityKeyPath)) as? Float) ?? 0
            toOpacity = 0
            fromPosition = (aLayer.presentation()?.value(forKeyPath: positionKeyPath) ?? aLayer.value(forKeyPath: positionKeyPath)) as? CGPoint ?? .zero
            toPosition = CGPoint(x: fromPosition.x, y: -aLayer.bounds.size.height)
        } else {
            fromOpacity = 0
            toOpacity = 1
            aLayer.position = CGPoint(x: 0, y: aLayer.bounds.size.height)
            aLayer.opacity = 0
            fromPosition = aLayer.position
            toPosition = CGPoint(x: 0, y: 0)
        }

        let opacityAnimation = CABasicAnimation(keyPath: opacityKeyPath)
        opacityAnimation.fromValue = fromOpacity
        opacityAnimation.toValue = toOpacity

        let moveAnimation = CABasicAnimation(keyPath: positionKeyPath)
        moveAnimation.fromValue = fromPosition
        moveAnimation.toValue = toPosition

        let group = CAAnimationGroup()
        group.animations = [moveAnimation, opacityAnimation]
        group.duration = 0.6
        group.beginTime = beginTime
        group.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        group.fillMode = .forwards
        group.isRemovedOnCompletion = false

        aLayer.position = fromPosition
        aLayer.opacity = fromOpacity
        aLayer.add(group, forKey: Constant.animationKey)
    }

    func createLayer(path: CharacterPath) -> CAShapeLayer {
        let shapeLayer = CAShapeLayer()
        shapeLayer.frame = bounds
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.white.cgColor
        shapeLayer.path = path.path.cgPath
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        shapeLayer.anchorPoint = .zero
        return shapeLayer
    }
}
