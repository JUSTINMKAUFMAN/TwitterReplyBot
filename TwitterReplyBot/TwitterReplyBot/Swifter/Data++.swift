import Foundation

extension Data {
    var rawBytes: [UInt8] { return [UInt8](self) }

    init(bytes: [UInt8]) {
        self.init(bytes: UnsafePointer<UInt8>(bytes), count: bytes.count)
    }

    mutating func append(_ bytes: [UInt8]) {
        append(UnsafePointer<UInt8>(bytes), count: bytes.count)
    }
}
