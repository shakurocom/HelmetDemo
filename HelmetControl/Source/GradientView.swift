import UIKit

class GradientView: UIView {

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    func setupGradient(_ setup: (_ gradientLayer: CAGradientLayer) -> Void) {
        guard let gradientLayer = layer as? CAGradientLayer else {
            return
        }
        setup(gradientLayer)
    }

}
