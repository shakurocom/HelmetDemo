import SpriteKit
import AVFoundation
import UIKit

final class HelmetAnimator {

    enum Constant {
        static let animationKey = "HelmetAnimation"

        static let decelerationDuration: TimeInterval = 0.5
        static let distanceToProgressFactor: CGFloat = 800
    }

    var animating: Bool {
        return node.action(forKey: Constant.animationKey) != nil
    }

    var progress: CGFloat {
        return CGFloat(lastFrameIndex) / CGFloat(frames.count - 1)
    }

    lazy var firstTexture: SKTexture? = {
        return atlas.textureNamed(textureNames[0])
    }()

    lazy private(set) var textureNames: [String] = {
        return atlas.textureNames.sorted()
    }()

    lazy private(set) var frames: [SKTexture] = {
        return textureNames.compactMap { (name) -> SKTexture? in
            return atlas.textureNamed(name)
        }
    }()

    private var atlas: RemoteTextureAtlas
    private let node: SKSpriteNode
    private var lastFrameIndex: Int = 0
    private var lastCounterClockwise: Bool = false

    init(node: SKSpriteNode, atlas: RemoteTextureAtlas) {
        self.atlas = atlas
        self.node = node
    }

    func performTransition(_ newAtlas: RemoteTextureAtlas, transitionEffect: SKEffectNode, counterClockwise: Bool) {
        removeAnimation(restore: false)

        let newFrames = newAtlas.textureNames.lazy.sorted().compactMap { (name) -> SKTexture? in
            return newAtlas.textureNamed(name)
        }
        let timePerFrame: TimeInterval = 1 / 150
        guard let action1 = animateAction(2, animateFrames: frames, timePerFrame: timePerFrame, counterClockwise: counterClockwise),
            let action2 = animateAction(2, animateFrames: newFrames, timePerFrame: timePerFrame, counterClockwise: counterClockwise),
            let nodeParent = node.parent else {
                return
        }
        lastCounterClockwise = counterClockwise
        nodeParent.childNode(withName: "transitionNode")?.removeFromParent()
        let transitionNode = SKSpriteNode()
        transitionNode.size = node.size
        transitionNode.position = node.position
        transitionNode.texture = newFrames[lastFrameIndex]
        transitionNode.zPosition = node.zPosition - 1
        transitionNode.color = .clear
        transitionNode.name = "transitionNode"
        nodeParent.addChild(transitionNode)

        atlas = newAtlas
        frames = newFrames
        let nodeName = node.name ?? ""
        let transitionNodeName = transitionNode.name ?? "transitionNode"
        let duration = timePerFrame * Double(newFrames.count)

        let filter: CIFilter? = CIFilter(name: "CIMotionBlur", parameters: ["inputRadius": NSNumber(value: 0)])
        transitionEffect.filter = filter
        transitionEffect.shouldEnableEffects = true

        let halfDuration = CGFloat(duration * 0.8)
        let maxRadius: CGFloat = 15
        let effectAction = SKAction.customAction(withDuration: duration) { (_, elapsedTime) in
            let radius: CGFloat
            if elapsedTime < halfDuration {
                radius = maxRadius * (elapsedTime / halfDuration)
            } else {
                radius = maxRadius * (1 - ((elapsedTime - halfDuration) / halfDuration))
            }
            filter?.setValue(NSNumber(value: Double(min(max(radius, 0), maxRadius))), forKey: "inputRadius")
        }

        let didFinishGroup = DispatchGroup()
        didFinishGroup.enter()
        let rotateAction1 = SKAction.run(.sequence([action1, .run {
            didFinishGroup.leave()
            }]), onChildWithName: nodeName)
        didFinishGroup.enter()
        let rotateAction2 = SKAction.run(.sequence([action2, .run {
            didFinishGroup.leave()
            }]), onChildWithName: transitionNodeName)
        didFinishGroup.enter()
        let fadeOut = SKAction.run( SKAction.sequence([.fadeOut(withDuration: duration), .run {
            didFinishGroup.leave()

            }]), onChildWithName: nodeName)
        let group = SKAction.group([effectAction, rotateAction1, rotateAction2, fadeOut])
        didFinishGroup.notify(queue: .main) { [weak self] in
            guard let actualSelf = self else {
                return
            }
            transitionEffect.shouldEnableEffects = false
            actualSelf.node.texture = transitionNode.texture
            transitionNode.removeFromParent()
            actualSelf.node.alpha = 1
        }
        nodeParent.run(group, withKey: Constant.animationKey)
    }

    func pause() {
        if !node.isPaused {
            node.isPaused = true
        }
        lastFrameIndex = frames.firstIndex(where: { $0 === node.texture }) ?? 0
    }

    func removeAnimation(restore: Bool) {
        if node.action(forKey: Constant.animationKey) != nil {
            node.removeAction(forKey: Constant.animationKey)
        }
        if restore {
            lastFrameIndex = 0
            node.texture = firstTexture
        } else {
            let texture = node.texture
            lastFrameIndex = frames.firstIndex(where: { $0 === texture }) ?? 0
        }
    }

    func animate(velocity: CGFloat) {
        let duration = Constant.decelerationDuration
        let addProgress = velocity * CGFloat(duration) / Constant.distanceToProgressFactor
        let counterClockwise = lastCounterClockwise
        let currentProgress = progress
        let action = SKAction.customAction(withDuration: duration) { [weak self] (_, elapsed) in
            guard let actualSelf = self else {
                return
            }
            let newProgress = (currentProgress - addProgress * elapsed).truncatingRemainder(dividingBy: 1)
            let toProgress = newProgress >= 0 ? newProgress : 1 + newProgress
            actualSelf.setProgress(toProgress, counterClockwise: counterClockwise)
        }
        action.timingFunction = { (value) -> Float in
            return value * (2.0 - value)
        }
        node.run(action, withKey: Constant.animationKey)
    }

    func animate(delay: TimeInterval = 0) {
        defer {
            if node.isPaused {
                node.isPaused = false
            }
        }
        guard node.action(forKey: Constant.animationKey) == nil, !frames.isEmpty else {
            return
        }
        let firstFrames = frames[lastFrameIndex..<frames.count]
        let lastFrames = lastFrameIndex > 0 ? frames[0..<lastFrameIndex] : []
        let toAnimateFrames: [SKTexture]
        if lastCounterClockwise {
            toAnimateFrames = Array(lastFrames.reversed()) + Array(firstFrames.reversed())
        } else {
            toAnimateFrames = Array(firstFrames + lastFrames)
        }
        let framesAction = SKAction.repeatForever(SKAction.animate(with: toAnimateFrames,
                                                                   timePerFrame: 1 / 24,
                                                                   resize: false,
                                                                   restore: false))
        framesAction.timingMode = .easeInEaseOut
        let action = delay > 0 ? SKAction.sequence([SKAction.wait(forDuration: delay), framesAction]) : framesAction
        node.run(action, withKey: Constant.animationKey)
    }

    func animateTo(_ progress: CGFloat, timePerFrame: TimeInterval = 1 / 24, counterClockwise: Bool = false) {
        lastCounterClockwise = counterClockwise
        if let action = animateAction(progress, animateFrames: frames, timePerFrame: timePerFrame, counterClockwise: counterClockwise) {
            node.run(action, withKey: Constant.animationKey)
        }
    }

    func setProgress(_ progress: CGFloat, counterClockwise: Bool = false) {
        lastCounterClockwise = counterClockwise
        let index = Int(floor(CGFloat(frames.count - 1) * progress))
        if lastFrameIndex != index,
            index < frames.count {
            lastFrameIndex = index
            node.texture = frames[index]
        }
    }

    func animateAction(_ animationProgress: CGFloat,
                       animateFrames: [SKTexture],
                       timePerFrame: TimeInterval = 1 / 24,
                       counterClockwise: Bool = false) -> SKAction? {
        let firstFrames = animateFrames[lastFrameIndex..<animateFrames.count]
        let lastFrames = animateFrames[0...lastFrameIndex]
        let fullCircleFrames: [SKTexture]
        if counterClockwise {
            fullCircleFrames = Array(lastFrames.reversed()) + Array(firstFrames.reversed())
        } else {
            fullCircleFrames = Array(firstFrames + lastFrames)
        }
        var toAnimateFrames: [SKTexture] = []
        var currentProgress = abs(animationProgress)
        while currentProgress > 1 {
            currentProgress -= 1
            toAnimateFrames.append(contentsOf: fullCircleFrames)
        }
        let remainingProgress = animationProgress >= 0 ? currentProgress : 1 - currentProgress
        let index = Int(floor(CGFloat(fullCircleFrames.count - 1) * remainingProgress))
        toAnimateFrames.append(contentsOf: fullCircleFrames[0...index])
        if !toAnimateFrames.isEmpty {
            let action = SKAction.animate(with: toAnimateFrames,
                                          timePerFrame: timePerFrame,
                                          resize: false,
                                          restore: false)
            action.timingMode = .easeInEaseOut
            return action
        } else {
            return nil
        }
    }
}
