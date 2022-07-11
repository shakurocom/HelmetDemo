import SpriteKit

extension CGPoint {

    func convertToSpriteKitCS(parentSize: CGSize, pointSpaceSize: CGSize) -> CGPoint {
        return CGPoint(x: x + (pointSpaceSize.width - parentSize.width) * 0.5, y: (parentSize.height - pointSpaceSize.height) * 0.5 - y)
    }

    func squaredDistance(to point: CGPoint) -> CGFloat {
        let xDistance = x - point.x
        let yDistance = y - point.y
        return xDistance * xDistance + yDistance * yDistance
    }

    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(squaredDistance(to: point))
    }

    static func * (left: CGPoint, right: CGFloat) -> CGPoint {
        return CGPoint(x: left.x * right, y: left.y * right)
    }

}
