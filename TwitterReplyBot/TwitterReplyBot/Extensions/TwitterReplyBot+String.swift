import AppKit
import Cocoa
import Foundation

public extension String {
    func countInstances(of string: String) -> Int {
        guard !string.isEmpty else { return 0 }
        var count: Int = 0
        var searchRange: Range<String.Index>?
        while let foundRange = range(of: string, options: [], range: searchRange) {
            count += 1
            searchRange = Range(uncheckedBounds: (lower: foundRange.upperBound, upper: endIndex))
        }
        return count
    }

    func height(width: CGFloat, font: NSFont?) -> CGFloat {
        let size = NSMakeSize(width, 0.0)
        var attributesDictionary: [NSAttributedString.Key: Any]?
        if let font = font { attributesDictionary = [.font: font as Any] }

        // swiftformat:disable all
        let bounds = self.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributesDictionary
        )
        // swiftformat:enable all

        return bounds.size.height
    }

    var mentions: [String] {
        return replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
            .flatMap { line in line.components(separatedBy: " ").filter { $0.hasPrefix("@") } }
    }

    var sanitized: String { return codeFormatting.unescaped }

    var importingFoundation: String {
        return (!contains("import Foundation") ? "import Foundation\n\n\(self)" : self)
    }

    var codeFormatting: String {
        return strippingMentions
            .replacingOccurrences(of: "“", with: "\"")
            .replacingOccurrences(of: "”", with: "\"")
            .importingFoundation
    }

    var strippingMentions: String {
        var result: String = self
        mentions.forEach { mention in result = result.replacingOccurrences(of: mention, with: "") }
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var asHeredoc: String {
        return #"""
        "$(cat << 'EOF'
        \#(self)
        EOF
        )"
        """#
    }

    var wrappedInQuotes: String { return #""\#(self)""# }

    var unescaped: String {
        let characterMap: [String: String] = [
            "&amp;": "&",
            "&lt;": "<",
            "&gt;": ">",
            "&quot;": "\"",
            "&apos;": "'"
        ]

        var result: String = self

        for (escapedChar, unescapedChar) in characterMap {
            result = result.replacingOccurrences(
                of: escapedChar,
                with: unescapedChar,
                options: NSString.CompareOptions.literal,
                range: nil
            )
        }

        return result
    }
}
