import Foundation

extension String {
    internal func indexOf(_ sub: String) -> Int? {
        guard let range = self.range(of: sub), !range.isEmpty else { return nil }
        return distance(from: startIndex, to: range.lowerBound)
    }

    internal subscript(r: Range<Int>) -> Substring {
        let startIndex = index(self.startIndex, offsetBy: r.lowerBound)
        let endIndex = index(startIndex, offsetBy: r.upperBound - r.lowerBound)
        return self[startIndex ..< endIndex]
    }

    func urlEncodedString(_ encodeAll: Bool = false) -> String {
        var allowedCharacterSet: CharacterSet = .urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\n:#/?@!$&'()*+,;=")
        if !encodeAll {
            allowedCharacterSet.insert(charactersIn: "[]")
        }
        return addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)!
    }

    var queryStringParameters: [String: String] {
        var parameters = [String: String]()
        let scanner = Scanner(string: self)
        var key: String?
        var value: String?

        while !scanner.isAtEnd {
            key = scanner.scanUpToString("=")
            _ = scanner.scanString(string: "=")

            value = scanner.scanUpToString("&")
            _ = scanner.scanString(string: "&")

            if let key = key, let value = value {
                parameters.updateValue(value, forKey: key)
            }
        }

        return parameters
    }
}
