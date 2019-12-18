import Foundation

extension Modules {
    static let bankVault: BankVault = BankVault()
}

class BankVault: Module {
    let handle: String = "Codebre42333063"

    func output(for reply: Reply, _ completion: @escaping ((String) -> Void)) {
        completion(response(for: reply.text))
    }

    func validate() {
        let testSuccess: String = "#ABBY"
        let testFailure: String = "AAAAAA"

        if testSuccess != "" {
            let result = response(for: testSuccess)
            print("TestSuccess: \(testSuccess) -> \(result)")
            assert(result == "🟢🟢🟢")
        }

        if testFailure != "" {
            let result = response(for: testFailure)
            print("TestFailure: \(testFailure) -> \(result)")
            assert(result != "🟢🟢🟢")
        }

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

private extension BankVault {
    static let key: String = "321"

    func response(for entry: String) -> String {
        let sum: String = String(entry.unicodeScalars.map { Int($0.value) }.reduce(0, +))
        return BankVault.key
            .enumerated()
            .map { ($0.0 >= sum.count) ? "⚫️" : ($0.1 == Array(sum)[$0.0]) ? "🟢" : $0.1 > Array(sum)[$0.0] ? "⬆️" : "⬇️" }
            .joined()
    }
}
