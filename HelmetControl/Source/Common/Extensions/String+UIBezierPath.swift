//
//  String+UIBezierPath.swift
//  ShakuroApp
//
//  Created by o on 08.09.2020.
//  Copyright © 2020 Shakuro. All rights reserved.
//

import UIKit

struct CharacterPath {
    let path: UIBezierPath
    let character: Character
    let position: CGPoint
}

struct StringPath {
    let path: UIBezierPath
    let paths: [CharacterPath]
    let transform: CGAffineTransform
}

extension String {

    func generatePath(font: UIFont) -> StringPath? {
        return generatePath(attributes: [.font: font])
    }

    func generatePath(attributes: [NSAttributedString.Key: Any]) -> StringPath? {
        guard let attrString = CFAttributedStringCreate(kCFAllocatorDefault, self as CFString, attributes as CFDictionary) else {
            return nil
        }

        var chPaths = [CharacterPath]()
        let totalPath = UIBezierPath()

        let line = CTLineCreateWithAttributedString(attrString)
        let runs = (CTLineGetGlyphRuns(line) as? [CTRun]) ?? []
        let lineHeight = CTLineGetBoundsWithOptions(line, [.useGlyphPathBounds]).size.height
        let pathTransform = CGAffineTransform(scaleX: 1, y: -1).concatenating(CGAffineTransform(translationX: 0, y: lineHeight))

        runs.forEach { (glyphRun) in
            guard let attributes = CTRunGetAttributes(glyphRun) as? [CFString: AnyObject], let font = attributes[kCTFontAttributeName] else {
                return
            }

            let glyphCount = CTRunGetGlyphCount(glyphRun)
            var positions = [CGPoint](repeating: CGPoint(), count: glyphCount)
            var glyphs = [CGGlyph](repeating: CGGlyph(), count: glyphCount)
            let range = CFRangeMake(0, glyphCount)
            CTRunGetGlyphs(glyphRun, range, &glyphs)
            CTRunGetPositions(glyphRun, range, &positions)

            let actualFont = unsafeBitCast(font, to: CTFont.self)
            (0..<glyphs.count).forEach { (index) in
                let glyph = glyphs[index]
                guard let path = CTFontCreatePathForGlyph(actualFont, glyph, nil) else {
                    return
                }
                let position = positions[index]
                let finalPath = UIBezierPath(cgPath: path)
                finalPath.apply(CGAffineTransform(translationX: position.x, y: position.y))
                finalPath.apply(pathTransform)
                totalPath.append(finalPath)
                chPaths.append(CharacterPath(path: finalPath, character: self[index], position: position))
            }
        }
        return StringPath(path: totalPath, paths: chPaths, transform: pathTransform)
    }

}
