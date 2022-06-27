import SpriteKit
// swiftlint:disable nesting
struct TextureOrigin: Codable {
    struct Rect: Codable {
        enum CodingKeys: String, CodingKey {
            case originX = "x"
            case originY = "y"
            case sizeW = "w"
            case sizeH = "h"
        }

        let value: CGRect

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            let originX = try values.decode(CGFloat.self, forKey: .originX)
            let originY = try values.decode(CGFloat.self, forKey: .originY)
            let sizeW = try values.decode(CGFloat.self, forKey: .sizeW)
            let sizeH = try values.decode(CGFloat.self, forKey: .sizeH)
            value = CGRect(x: originX, y: originY, width: sizeW, height: sizeH)
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(value.origin.x, forKey: .originX)
            try container.encode(value.origin.y, forKey: .originY)
            try container.encode(value.size.width, forKey: .sizeW)
            try container.encode(value.size.height, forKey: .sizeH)
        }
    }

    let frame: Rect

    static func decode(_ data: Data?) -> TextureOrigin? {
        return try? JSONDecoder.decode(self, from: data)
    }

    func encode() -> Data? {
        return try? JSONEncoder.encode(self)
    }

    func relativeFrame(_ size: CGSize) -> CGRect {
        let rect = frame.value
        let relativeW = rect.size.width / size.width
        let relativeH = rect.size.height / size.height
        let relativeX = rect.origin.x / size.width
        let relativeY = (1 - rect.origin.y / size.height) - relativeH
        return CGRect(x: relativeX, y: relativeY, width: relativeW, height: relativeH)
    }
}

final class RemoteTextureAtlas {
    let textureNames: [String]

    let rootTextures: [SKTexture]
    let textures: [String: SKTexture]
    let sourceUrl: URL

    static func load(_ url: URL,
                     completion: @escaping (_ atlas: RemoteTextureAtlas?) -> Void) -> DispatchWorkItem {
        var cancelable: DispatchWorkItem?
        let item = DispatchWorkItem {
            defer {
                cancelable = nil
            }
            guard let actualItem = cancelable, !actualItem.isCancelled else {
                return
            }
            let result = load(url, cancelable: actualItem)
            if !actualItem.isCancelled {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
        cancelable = item
        DispatchQueue.global(qos: .userInitiated).async(execute: item)
        return item
    }

    static func load(_ url: URL, cancelable: DispatchWorkItem?) -> RemoteTextureAtlas? {
        var cancelled: Bool = false
        let isCancelled = { () -> Bool in
            guard cancelled else {
                return cancelled
            }
            cancelled = (cancelable?.isCancelled ?? false)
            return cancelled
        }

        let fileManager = FileManager()
        let files = (try? fileManager.contentsOfDirectory(at: url,
                                                          includingPropertiesForKeys: nil,
                                                          options: [.skipsHiddenFiles])) ?? []
        var rootUrls: [String: URL] = [:]
        var rootMetadataUrls: [String: URL] = [:]
        for url in files {
            guard !isCancelled() else {
                break
            }
            let name = url.deletingPathExtension().lastPathComponent
            if url.pathExtension.lowercased() == "json" {
                rootMetadataUrls[name] = url
            } else {
                rootUrls[name] = url
            }
        }

        guard !isCancelled(), !rootUrls.isEmpty, !rootMetadataUrls.isEmpty else {
            return nil
        }

        var roots: [SKTexture] = []
        var names: [String] = []
        var preparedTextures: [String: SKTexture] = [:]

        for rootEntry in rootUrls {
            guard !isCancelled() else {
                break
            }
            if let imageData = try? Data(contentsOf: rootEntry.value),
               let image = UIImage(data: imageData),
               let metaURL = rootMetadataUrls[rootEntry.key],
               let metadata = try? Data(contentsOf: metaURL),
               let atlasInfo = AtlasInfo.decode(metadata) {
                let root = SKTexture(image: image)
                let imageSize = image.size
                let imageScale = image.scale
                let rootSize = CGSize(width: max(imageSize.width, 1) * imageScale,
                                      height: max(imageSize.height, 1) * imageScale)
                for entry in atlasInfo.frames {
                    guard !isCancelled() else {
                        break
                    }
                    let childRect = entry.value.relativeFrame(rootSize)
                    let texture = SKTexture(rect: childRect, in: root)
                    names.append(entry.key)
                    preparedTextures[entry.key] = texture
                }
                roots.append(root)
            }
        }
        guard !isCancelled() else {
            return nil
        }
        return RemoteTextureAtlas(url, rootTextures: roots, textures: preparedTextures, textureNames: names)
    }

    init(_ url: URL, rootTextures: [SKTexture], textures: [String: SKTexture], textureNames: [String]) {
        self.rootTextures = rootTextures
        self.textures = textures
        self.textureNames = textureNames
        sourceUrl = url
    }

    func textureNamed(_ name: String) -> SKTexture {
        guard let actualTexture = textures[name] else {
            assertionFailure()
            return SKTexture(image: UIImage())
        }
        return actualTexture
    }

    func preload(completionHandler: @escaping () -> Void) {
        guard !textures.isEmpty else {
            completionHandler()
            return
        }
        SKTexture.preload(rootTextures, withCompletionHandler: completionHandler)
    }
}

private struct AtlasInfo: Codable {

    enum CodingKeys: String, CodingKey {
        case frames
        case meta
    }

    let frames: [String: TextureOrigin]
    let meta: [String: String]?

    init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer(),
            let actualFrames = try? value.decode([String: TextureOrigin].self) {
            frames = actualFrames
            meta = nil
        } else {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            frames = try values.decode([String: TextureOrigin].self, forKey: .frames)
            meta = try? values.decode([String: String].self, forKey: .meta)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(frames, forKey: .frames)
        try container.encode(meta, forKey: .meta)
    }

    static func decode(_ data: Data?) -> AtlasInfo? {
        return try? JSONDecoder.decode(self, from: data)
    }

    func encode() -> Data? {
        return try? JSONEncoder.encode(self)
    }
}
// swiftlint:enable nesting
