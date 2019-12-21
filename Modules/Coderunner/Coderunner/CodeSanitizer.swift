import Foundation

extension String {
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

    var mentions: [String] {
        return replacingOccurrences(of: "\r\n", with: "\n")
            .components(separatedBy: "\n")
            .flatMap { line in line.components(separatedBy: " ").filter { $0.hasPrefix("@") } }
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
