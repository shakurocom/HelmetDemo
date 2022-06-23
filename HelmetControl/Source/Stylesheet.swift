import UIKit
import Shakuro_iOS_Toolbox

enum Stylesheet {

    // MARK: - Fonts

    enum FontFace: String {
        case dinCondensedBold = "DINCondensed-Bold"
        case haveHeartOne = "HaveHeartOne"
        case sfProMedium = "SFPro-Medium"
    }

}

// MARK: - Helpers

extension Stylesheet.FontFace {

    func fontWithSize(_ size: CGFloat) -> UIFont {
        guard let actualFont: UIFont = UIFont(name: self.rawValue, size: size) else {
            debugPrint("Can't load font with name!!! \(self.rawValue)")
            return UIFont.systemFont(ofSize: size)
        }
        return actualFont
    }

    static func printAvailableFonts() {
        for name in UIFont.familyNames {
            debugPrint("<<<<<<< Font Family: \(name)")
            for fontName in UIFont.fontNames(forFamilyName: name) {
                debugPrint("Font Name: \(fontName)")
            }
        }
    }

}
