//
//  HelmetBundleHelper.swift
//

import Foundation
import UIKit
import Shakuro_CommonTypes

final class HelmetBundleHelper {

    private static let bundleHelper: BundleHelper = {
        let bundleHelper = BundleHelper(targetClass: HelmetViewController.self, bundleName: "Helmet")
        let fonts: [(fontName: String, fontExtension: String)] = [
            (fontName: "SF-Pro-Text-Medium", fontExtension: "otf"),
            (fontName: "HaveHeartOne", fontExtension: "otf")
        ]
        bundleHelper.registerFonts(fonts)
        return bundleHelper
    }()

    private static let bundle: Bundle = {
        let helmetBundle = Bundle(for: HelmetViewController.self)
        if let helmetBundleURL = helmetBundle.url(forResource: "Helmet", withExtension: "bundle"),
           let helmetBundleInternal = Bundle(url: helmetBundleURL) {
            return helmetBundleInternal
        } else {
            return helmetBundle
        }
    }()

    /// Returns the file URL for the resource identified by the specified name and file extension.
    /// - parameter name: The name of the resource file.
    /// - parameter extension: The extension of the resource file.
    static func url(forResource name: String, withExtension ext: String?) -> URL? {
        return bundle.url(forResource: name, withExtension: ext)
    }

    /// Returns an image object using the named image asset that is compatible with the specified trait collection.
    /// - parameter named: image name.
    /// - parameter traitCollection: The traits associated with the intended environment for the image. Use this parameter to ensure that the correct variant of the image is loaded. If you specify nil, this method uses the traits associated with the main screen.
    static func image(named: String, compatibleWith: UITraitCollection? = nil) -> UIImage? {
        return bundleHelper.image(named: named, compatibleWith: compatibleWith)
    }

    /// Reads a color with the specified name from the bundle.
    /// - parameter named: color name.
    static func color(named: String, compatibleWith: UITraitCollection? = nil) -> UIColor? {
        return bundleHelper.color(named: named, compatibleWith: compatibleWith)
    }

    /**
     Returns instance of a UIViewController.

     - Parameters:
        - targetClass: View controller type,  that must be created.
        - nibName: The name of the nib file to associate with the view controller.
     - Returns: A newly initialized UIViewController object.

     - Example:
     `let exampleViewController: ExampleViewController = BundleHelper.instantiateViewControllerFromBundle(targetClass: ExampleViewController.type, nibName: "kExampleViewController")`
     */
    static func instantiateViewController<T>(targetClass: T.Type, nibName: String) -> T where T: UIViewController {
        return bundleHelper.instantiateViewController(targetClass: targetClass, nibName: nibName)
    }

}
