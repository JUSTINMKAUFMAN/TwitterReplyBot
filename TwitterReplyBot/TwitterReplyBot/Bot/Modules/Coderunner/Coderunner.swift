import Cocoa
import Foundation

class Coderunner: Module {
    let handle: String = "code_swift"
    let blacklist: [String] = ["1203814934510858240"]

    func output(for reply: Reply, _ completion: @escaping ((String) -> Void)) {
        guard let path = Bundle.main.path(forResource: "Coderunner", ofType: nil) else {
            fatalError("Could not find Coderunner command line tool in bundle!")
        }

        let task: Process = Process()
        let pipe: Pipe = Pipe()
        let id: String = reply.id.wrappedInQuotes
        let code: String = reply.text.sanitized.asHeredoc
        let command: String = "\(path) \(id) \(code)"

        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        task.standardOutput = pipe

        let outputHandle = pipe.fileHandleForReading
        outputHandle.waitForDataInBackgroundAndNotify()

        var dataAvailableObserver: NSObjectProtocol!
        var dataReadyObserver: NSObjectProtocol!

        dataAvailableObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSFileHandleDataAvailable,
            object: outputHandle,
            queue: nil
        ) { _ -> Void in
            let data = pipe.fileHandleForReading.availableData

            if data.count > 0 {
                if let result = String(data: data, encoding: .utf8) {
                    let response = self.response(for: result, with: id)
                    kill(task.processIdentifier, 0)
                    completion(response)
                }
                outputHandle.waitForDataInBackgroundAndNotify()
            } else {
                if let dataAvailableObserver = dataAvailableObserver {
                    NotificationCenter.default.removeObserver(dataAvailableObserver)
                }
            }
        }

        dataReadyObserver = NotificationCenter.default.addObserver(
            forName: Process.didTerminateNotification,
            object: pipe.fileHandleForReading,
            queue: nil
        ) { _ -> Void in
            if let dataReadyObserver = dataReadyObserver {
                NotificationCenter.default.removeObserver(dataReadyObserver)
            }
        }

        task.launch()
    }

    func validate() {
        output(for: Constants.basicReply) { basicResult in
            assert(basicResult == "Test Success: TwitterReplyBot")
        }

        output(for: Constants.timeoutReply) { timeoutResult in
            assert(timeoutResult == "Code execution either took too long or did not produce any output.")
        }
    }

    required init() {}
}

private extension Coderunner {
    func response(for result: String, with id: String) -> String {
        let response: String = String(
            (result.isEmpty ? "Code either had an error or did not produce any output.\n\nFix any mistakes and/or make sure you are printing something." : result)
                .unescaped
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(280)
        )

        return response
    }
}

private extension Coderunner {
    struct Constants {
        static let timeoutCode: String =
            """
            import Foundation

            var count: Int = 0

            func testA() {
                while (count != -1) {
                    count += 1
                }
            }

            testA()

            print("Count: \\(count)")
            """

        static let basicCode: String =
            """
            import Foundation

            func tester(_ string: String) -> String {
                return "Test Success: \\(string)"
            }

            let test: String = "TwitterReplyBot"

            print(tester(test))
            """

        static let timeoutReply = Reply(
            id: UUID().uuidString,
            text: timeoutCode,
            authorId: twitterAccountId,
            authorHandle: "TwitterReplyBot",
            timestamp: "39479234762"
        )

        static let basicReply = Reply(
            id: UUID().uuidString,
            text: basicCode,
            authorId: twitterAccountId,
            authorHandle: "JUSTINMKAUFMAN",
            timestamp: "39479239340"
        )
    }
}

// MARK: Convenience

extension Modules {
    static let coderunner: Coderunner = Coderunner()
}
