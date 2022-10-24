import Foundation

extension JSONEncoder {

    static func encode<T>(_ value: T) throws -> Data? where T: Encodable {
        var result: Data?
        try autoreleasepool {
            result = try JSONEncoder().encode(value)
        }
        return result
    }

}

extension JSONDecoder {

    static func decode<T>(_ type: T.Type, from data: Data?) throws -> T? where T: Decodable {
        guard let actualData = data else {
            return nil
        }
        var result: T?
        try autoreleasepool {
            result = try JSONDecoder().decode(T.self, from: actualData)
        }
        return result
    }

}
