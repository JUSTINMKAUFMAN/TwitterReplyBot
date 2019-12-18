import Foundation

class StringEncrypter: Module {
    let handle: String = "JUSTINMKAUFMAN"

    func output(for reply: Reply, _ completion: @escaping ((String) -> Void)) {
        completion(encrypt(reply.text))
    }

    func validate() {
        let testTweet: Reply = Reply(
            id: UUID().uuidString,
            text: "This is a test",
            authorId: twitterAccountId,
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

extension Modules {
    static let stringEncrypter: StringEncrypter = StringEncrypter()
}
