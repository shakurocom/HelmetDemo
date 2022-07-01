//
//  Bundle+Helper.swift
//

import Foundation

extension Bundle {

    static func findBundleIfNeeded(for aClass: AnyClass) -> Bundle {
        if let podBundleURL = Bundle(for: aClass).url(forResource: "Helmet", withExtension: "bundle"),
           let podBundle = Bundle(url: podBundleURL) {
            return podBundle
        }
        return Bundle.main
    }

}
