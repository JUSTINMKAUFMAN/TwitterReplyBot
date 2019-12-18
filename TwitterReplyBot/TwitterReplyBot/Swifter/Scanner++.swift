import Foundation

extension Scanner {
    #if os(Linux)
        func scanString(string: String) -> String? {
            var buffer: String?
            _ = scanString(string, into: &buffer)
            return buffer
        }

    #elseif os(iOS) || os(macOS)
        func scanString(string: String) -> String? {
            var buffer: NSString?
            _ = scanString(string, into: &buffer)
            return buffer as String?
        }
    #endif

    #if os(iOS) || os(macOS)
        func scanUpToString(_ string: String) -> String? {
            var buffer: NSString?
            scanUpTo(string, into: &buffer)
            return buffer as String?
        }
    #endif

    #if os(Linux)
        var isAtEnd: Bool {
            return scanLocation == string.utf16.count
        }
    #endif
}
