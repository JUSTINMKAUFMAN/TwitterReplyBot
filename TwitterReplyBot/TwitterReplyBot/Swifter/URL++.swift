import Foundation

extension URL {
    func append(queryString: String) -> URL {
        guard !queryString.utf16.isEmpty else { return self }

        var absoluteURLString = absoluteString

        if absoluteURLString.hasSuffix("?") {
            absoluteURLString = String(absoluteURLString[0 ..< absoluteURLString.utf16.count])
        }

        let urlString = absoluteURLString + (absoluteURLString.range(of: "?") != nil ? "&" : "?") + queryString
        return URL(string: urlString)!
    }

    func hasSameUrlScheme(as otherUrl: URL) -> Bool {
        guard let scheme = self.scheme, let otherScheme = otherUrl.scheme else { return false }
        return scheme.caseInsensitiveCompare(otherScheme) == .orderedSame
    }

    var queryParamsForSSO: [String: String] {
        guard let host = self.host else { return [:] }
        return host.split(separator: "&").reduce(into: [:]) { result, parameter in
            let keyValue = parameter.split(separator: "=")
            result[String(keyValue[0])] = String(keyValue[1])
        }
    }
}
