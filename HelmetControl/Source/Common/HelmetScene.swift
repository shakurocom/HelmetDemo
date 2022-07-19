//
//  HelmetScene.swift
//  ShakuroApp
//
//  Created by Vlad Onipchenko on 8/12/20.
//  Copyright © 2020 Shakuro. All rights reserved.
//

import SpriteKit

final class HelmetScene: SKScene {

    private enum Constant {
        static let buttonSize = CGSize(width: 112, height: 112)
        static let buttonInnerRadius: CGFloat = 24
        static let outerRadius: CGFloat = buttonSize.width * 0.5
    }

    let panGestureRecognizer = UIPanGestureRecognizer()
    let tapGestureRecognizer = UITapGestureRecognizer()

    var didSelectBlackHelmet: (() -> Void)?
    var didSelectPinkHelmet: (() -> Void)?

    private var blackHelmet: RemoteTextureAtlas?
    private var purpleHelmet: RemoteTextureAtlas?
    private var blackHelmetLoadItem: DispatchWorkItem?
    private var purpleHelmetLoadItem: DispatchWorkItem?

    private var animator: HelmetAnimator?

    private let contentNode = SKNode()
    private let helmetNode = SKSpriteNode()
    private let effectNode = SKEffectNode()
    private var textureSize: CGSize = CGSize(width: 1, height: 1)

    private var titleNode = LabelEffectNode()

    private let blackButton = CircleShapeButton(UIColor(hex: "#4F596D"), innerRadius: Constant.buttonInnerRadius, outerRadius: Constant.outerRadius)
    private let pinkButton = CircleShapeButton(UIColor(hex: "#FC5185"), innerRadius: Constant.buttonInnerRadius, outerRadius: Constant.outerRadius)
    // private let purpleButton = CircleShapeButton(UIColor(hex: "#B14EF7"), innerRadius: Constant.buttonInnerRadius, outerRadius: Constant.outerRadius)
    private let indicatorNode = IndicatorNode(UIColor(hex: "#4F596D"), radius: Constant.outerRadius)
    private var lastTouchLocation: CGPoint?
    private var progress: CGFloat = 0
    private var firstShow: Bool = true

    private var nodesAreReady: Bool = false
    private var loadingAtlasses: Bool = false

    override init(size: CGSize = CGSize(width: 1, height: 1)) {
        super.init(size: size)
        loadHelmets()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadHelmets()
    }

    deinit {
        cancelHelmetsLoading()
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        scaleMode = .resizeFill
        setupNodes()
        finishSetup()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        updateLayout()
    }

    func didAppear() {
        guard firstShow else {
            return
        }
        firstShow = false
    }

}

// MARK: - Touches

extension HelmetScene: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer === panGestureRecognizer
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer === panGestureRecognizer || gestureRecognizer === tapGestureRecognizer {
            let res = [pinkButton, blackButton].contains { (button) -> Bool in
                let location = touch.location(in: helmetNode)
                return button.contains(location)
            }
            return !res
        } else {
            return false
        }
    }
}

// MARK: - Private

private extension HelmetScene {

    @objc func handleGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .possible:
            break
        case .began:
            lastTouchLocation = touchLocation()
            if let actualAnimator = animator {
                actualAnimator.removeAnimation(restore: false)
                progress = actualAnimator.progress
            }
        case .changed:
            let location = touchLocation()
            let lastLocation = lastTouchLocation ?? location
            lastTouchLocation = location
            handleLocation(location, lastLocation: lastLocation, animated: false)
        case .ended, .cancelled, .failed:
            lastTouchLocation = nil
            guard let actualView = view else {
                return
            }
            let velocity = panGestureRecognizer.velocity(in: actualView)
            animator?.animate(velocity: velocity.x)
        @unknown default:
            break
        }
    }

    func handleLocation(_ location: CGPoint, lastLocation: CGPoint, animated: Bool) {
        let movementX = (location.x - lastLocation.x) / size.width
        let rawProgress = progress - movementX
        let truncatedProgress = rawProgress.truncatingRemainder(dividingBy: 1)
        progress = truncatedProgress >= 0 ? truncatedProgress : 1 + truncatedProgress
        let counterClockwise = location.x > lastLocation.x
        if animated {
            animator?.animateTo(abs(rawProgress), counterClockwise: counterClockwise)
        } else {
            animator?.setProgress(abs(progress), counterClockwise: counterClockwise)
        }
    }

    func touchLocation() -> CGPoint {
        guard let actualView = view else {
            return .zero
        }
        return actualView.convert(panGestureRecognizer.location(in: actualView), to: self)
    }

    func updateLayout() {
        let scale = size.width / textureSize.width
        contentNode.xScale = scale
        contentNode.yScale = scale
        contentNode.position = CGPoint(x: size.width * 0.5, y: (textureSize.height * scale * 0.5))
    }

    func cancelHelmetsLoading() {
        blackHelmetLoadItem?.cancel()
        purpleHelmetLoadItem?.cancel()
        blackHelmetLoadItem = nil
        purpleHelmetLoadItem = nil
    }

    func loadHelmets() {
        guard let blackUrl = HelmetBundleHelper.url(forResource: "BlackHelmetAtlas", withExtension: nil),
              let purpleUrl = HelmetBundleHelper.url(forResource: "PurpleHelmetAtlas", withExtension: nil) else {
            return
        }
        cancelHelmetsLoading()
        loadingAtlasses = true
        isUserInteractionEnabled = false
        var blackAtlas: RemoteTextureAtlas?
        var purpleAtlas: RemoteTextureAtlas?
        let loadGroup = DispatchGroup()
        loadGroup.enter()
        blackHelmetLoadItem = RemoteTextureAtlas.load(blackUrl) { (atlas) in
            blackAtlas = atlas
            if let actualAtlas = atlas {
                actualAtlas.preload {
                    loadGroup.leave()
                }
            } else {
                loadGroup.leave()
            }
        }
        loadGroup.enter()
        purpleHelmetLoadItem = RemoteTextureAtlas.load(purpleUrl) { (atlas) in
            atlas?.preload {}
            purpleAtlas = atlas
            loadGroup.leave()
        }
        loadGroup.notify(queue: .main) { [weak self] in
            guard let actualSelf = self else {
                return
            }
            actualSelf.blackHelmet = blackAtlas
            actualSelf.purpleHelmet = purpleAtlas
            actualSelf.loadingAtlasses = false
            actualSelf.finishSetup()
            actualSelf.isUserInteractionEnabled = true
        }
    }

    func finishSetup() {
        guard nodesAreReady, !loadingAtlasses, let atlas = blackHelmet else {
            return
        }
        let helmetAnimator = HelmetAnimator(node: helmetNode, atlas: atlas)
        progress = 0
        helmetAnimator.setProgress(progress, counterClockwise: true)
        animator = helmetAnimator
        blackButton.action = { [weak self] in
            guard let actualSelf = self, let helmetAtlas = actualSelf.blackHelmet else {
                return
            }
            actualSelf.titleNode.setText(NSLocalizedString("Scorpion", comment: ""), animated: true)
            // actualSelf.purpleButton.isSelected = false
            actualSelf.blackButton.isSelected = true
            actualSelf.indicatorNode.moveTo(point: actualSelf.blackButton.position, animated: true)
            actualSelf.animator?.performTransition(helmetAtlas, transitionEffect: actualSelf.effectNode, counterClockwise: false)
            actualSelf.didSelectBlackHelmet?()
        }
        pinkButton.action = { [weak self] in
            guard let actualSelf = self, let helmetAtlas = actualSelf.purpleHelmet else {
                return
            }
            actualSelf.titleNode.setText(NSLocalizedString("Chameleon", comment: ""), animated: true)
            actualSelf.pinkButton.isSelected = true
            actualSelf.blackButton.isSelected = false
            actualSelf.indicatorNode.moveTo(point: actualSelf.pinkButton.position, animated: true)
            actualSelf.animator?.performTransition(helmetAtlas, transitionEffect: actualSelf.effectNode, counterClockwise: true)
            actualSelf.didSelectPinkHelmet?()
        }
        panGestureRecognizer.addTarget(self, action: #selector(handleGestureRecognizer(_:)))
        panGestureRecognizer.delegate = self
        view?.addGestureRecognizer(panGestureRecognizer)

        tapGestureRecognizer.require(toFail: panGestureRecognizer)
    }

    func setupNodes() {
        let texture = SKTexture(image: HelmetBundleHelper.image(named: "blackHelmet-0") ?? UIImage())
        textureSize = texture.size()
        helmetNode.size = textureSize
        helmetNode.texture = texture
        helmetNode.color = .clear
        helmetNode.name = "helmetNode"
        effectNode.addChild(helmetNode)
        effectNode.shouldEnableEffects = false
        effectNode.shouldCenterFilter = true
        effectNode.shouldRasterize = false
        contentNode.addChild(effectNode)

        let originY = textureSize.height - Constant.buttonSize.height - 4
        let originX = (textureSize.width - Constant.buttonSize.width) * 0.5 - (Constant.buttonSize.width + 10) * 0.5

        blackButton.isUserInteractionEnabled = true
        blackButton.zPosition = 100
        blackButton.position = CGPoint(x: originX, y: originY).convertToSpriteKitCS(parentSize: textureSize, pointSpaceSize: Constant.buttonSize)

        // purpleButton.zPosition = 100
        // purpleButton.position = CGPoint(x: originX - Constant.buttonSize.width - 10, y: originY).convertToSpriteKitCS(parentSize: textureSize, pointSpaceSize: Constant.buttonSize)

        pinkButton.isUserInteractionEnabled = true
        pinkButton.zPosition = 100
        pinkButton.position = CGPoint(x: originX + Constant.buttonSize.width + 10, y: originY).convertToSpriteKitCS(parentSize: textureSize, pointSpaceSize: Constant.buttonSize)

        indicatorNode.zPosition = 100
        indicatorNode.position = blackButton.position

        contentNode.addChild(blackButton)
        contentNode.addChild(pinkButton)
        // contentNode.addChild(purpleButton)
        contentNode.addChild(indicatorNode)

        addChild(contentNode)

        blackButton.isSelected = true

        titleNode.font = Stylesheet.FontFace.haveHeartOne.fontWithSize(228)
        titleNode.zPosition = 2000
        titleNode.setText(NSLocalizedString("Scorpion", comment: ""), animated: false)
        titleNode.position = CGPoint(x: 0, y: 440)
        contentNode.addChild(titleNode)
        updateLayout()

        nodesAreReady = true
    }
}
