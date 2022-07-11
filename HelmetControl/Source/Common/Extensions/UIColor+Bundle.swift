//
//  UIColor+Bundle.swift
//

import UIKit

extension UIColor {

    static func loadColorFromBundle(name: String) -> UIColor? {
        return UIColor(named: name, in: Bundle.findBundleIfNeeded(for: HelmetViewController.self), compatibleWith: nil)
    }

}
