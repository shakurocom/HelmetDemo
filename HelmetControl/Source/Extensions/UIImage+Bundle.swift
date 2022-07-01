//
//  UIImage+Bundle.swift
//

import UIKit

public extension UIImage {

    static func loadImageFromBundle(name: String) -> UIImage? {
        return UIImage(named: name, in: Bundle.findBundleIfNeeded(for: HelmetViewController.self), compatibleWith: nil)
    }

}
