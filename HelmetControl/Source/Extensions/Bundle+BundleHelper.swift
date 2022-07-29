//
//  Bundle+BundleHelper.swift
//

import Foundation
import Shakuro_CommonTypes

extension Bundle {
    
    static let helmetBundleHelper: BundleHelper = {
        let bundleHelper = BundleHelper(targetClass: HelmetViewController.self, bundleName: "Helmet")
        let fonts: [(fontName: String, fontExtension: String)] = [
            (fontName: "SF-Pro-Text-Medium", fontExtension: "otf"),
            (fontName: "HaveHeartOne", fontExtension: "otf")
        ]
        bundleHelper.registerFonts(fonts)
        return bundleHelper
    }()

}
