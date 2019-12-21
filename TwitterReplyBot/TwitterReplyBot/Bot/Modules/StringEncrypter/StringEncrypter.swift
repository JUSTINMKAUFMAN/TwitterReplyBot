import Foundation

/**
 See the following link for more info:
 https://github.com/JUSTINMKAUFMAN/TwitterCodebreaker
 */
class StringEncrypter: Module {
    let handle: String = "code_swift"

    func output(for reply: Reply, _ completion: @escaping ((String) -> Void)) {
        completion(encrypt(reply.text))
    }

    func validate() {
        let testTweet: Reply = Reply(
            id: UUID().uuidString,
            text: "This is a test",
            authorId: "3947394",
            authorHandle: "JUSTINMKAUFMAN",
            timestamp: "29375395729"
        )

        output(for: testTweet) { result in
            assert(result == "Ujlw%oz(j*q")
        }
    }

    required init() {}
}

private extension StringEncrypter {
    func encrypt(_ text: String) -> String {
        return String(text.unicodeScalars.enumerated().map { Character(UnicodeScalar($0.1.value + (UInt32($0.0) + 1))!) })
    }

    func decrypt(_ text: String) -> String {
        return String(text.unicodeScalars.enumerated().map { Character(UnicodeScalar($0.1.value - (UInt32($0.0) + 1))!) })
    }
}

// MARK: Convenience

extension Modules {
    static let stringEncrypter: StringEncrypter = StringEncrypter()
}
