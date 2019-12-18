import Foundation

struct RunConfig {
    let id: String
    let code: String
}

struct Command {
    let launchPath: String
    let arguments: [String]
}

struct Output {
    var statusCode: Int
    var result: String
}

extension CommandRunner {
    @discardableResult
    static func swift(run swiftCode: String, id: String, timeout: TimeInterval? = nil) -> Output {
        let file: String = "\(id).swift"
        let result: String = "\(id).txt"
        let code: String = swiftCode.sanitized

        if let interceptMessage: String = safetyWarning(code) {
            let response = Output(statusCode: 1, result: interceptMessage)
            write(response.result, result)
            return response
        }

        let command: String = "cat << 'EOF' >> \(file)\n\(code)\nEOF\n"
        let runner = CommandRunner([
            Command(launchPath: "/bin/bash", arguments: ["-c", "touch \(file)"]),
            Command(launchPath: "/bin/bash", arguments: ["-c", "chmod +x \(file)"]),
            Command(launchPath: "/bin/bash", arguments: ["-c", command]),
            Command(launchPath: "/bin/bash", arguments: ["-c", "swift \(file)"])
        ])

        if let timeout = timeout {
            DispatchQueue.global().asyncAfter(
                deadline: .now() + timeout,
                execute: { [weak runner] in
                    guard let runner = runner else { return }
                    if runner.isRunning {
                        let error: String = "Code execution either took too long or did not produce any output."
                        runner.terminate()
                        write(error, result)
                        print(error)
                        exit(0)
                    }
                }
            )
        }

        let output: Output = runner.execute()
        write(output.result, result)
        return output
    }

    @discardableResult
    static func write(_ text: String, _ file: String) -> Output {
        let command: String = "cat << 'EOF' >> \(file)\n\(text)\nEOF\n"
        return CommandRunner([
            Command(launchPath: "/bin/bash", arguments: ["-c", "touch \(file)"]),
            Command(launchPath: "/bin/bash", arguments: ["-c", command]),
            Command(launchPath: "/bin/bash", arguments: ["-c", "echo \"$(PWD)/\(file)\""])
        ]).execute()
    }

    static func echoResult(_ result: String) {
        CommandRunner([Command(launchPath: "/bin/bash", arguments: ["-c", "echo \(result)"])]).execute()
    }

    static func config(from arguments: [String]) -> RunConfig? {
        guard arguments.count == 3 else {
            print("Wrong number of arguments [\(arguments.count)]:\n\(arguments)")
            return nil
        }

        let id: String = arguments[1]
        let code: String = arguments[2]
        return RunConfig(id: id, code: code)
    }

    static func safetyWarning(_ code: String) -> String? {
        if code.contains("Process") || code.contains("Task") {
            return "This bot does not allow code to run out of process. Please only use this bot to evaluate basic expressions and print the result."
        }

        if code.contains("Dispatch") ||
            code.contains("Queue") ||
            code.contains("Operation") ||
            code.contains("Notification") ||
            code.lowercased().contains("thread") ||
            code.contains("async") {
            return "This bot does not allow multi-threaded or asynchronous operations. Please only use this bot to evaluate basic expressions and print the result."
        }

        if code.contains("Host") ||
            code.contains("Request") ||
            code.contains("URL") ||
            code.contains("Application") ||
            code.contains("Delegate") ||
            code.lowercased().contains("ipaddress") {
            return "This bot does not allow networking code. Please only use this bot to evaluate basic expressions and print the result."
        }

        if code.contains("File") ||
            code.contains("UserDefaults") ||
            code.contains("System") ||
            code.contains("Pasteboard") ||
            code.lowercased().contains("path") {
            return "This bot does not permit access to the host file system. Please only use this bot to evaluate basic expressions and print the result."
        }

        if !(code.components(separatedBy: "\n").filter { $0.starts(with: "import") && !$0.contains("Foundation") }).isEmpty ||
            code.contains("Cocoa") ||
            code.contains("AppKit") {
            return "This bot does not allow importing frameworks other than Foundation."
        }

        let unsafeOperations: [String] = [
            "NSC", "CF", "kill", "exit", "terminate", "delete", "execute", "launch", "chmod", "\nsh ", "\rsh ", "\tsh ", " sh ", "sleep", "echo", "Unsafe", "unsafe"
        ]

        for op in unsafeOperations {
            if code.contains(op) {
                return "One or more operations in your code were not permitted. Please only use this bot to evaluate basic expressions and print the result [\(op)]"
            }
        }

        return nil
    }

    static func runTests() {
        print("Running Tests:\n")

        print("[1/3] Running Literal Test...")
        let literalId: String = UUID().uuidString
        let literalResult = CommandRunner.swift(run: TestCode.LiteralParam, id: literalId, timeout: 10.0)
        print("[1/3] Exit Code: \(literalResult.statusCode) | \(literalResult.result)\n\n")

        print("[2/3] Running Basic Print Test...")
        let printId: String = UUID().uuidString
        let printResult = CommandRunner.swift(run: TestCode.BasicPrint, id: printId, timeout: 10.0)
        print("[2/3] Exit Code: \(printResult.statusCode) | \(printResult.result)\n\n")

        print("[3/3] Running Timeout Test...")
        let timeoutId: String = UUID().uuidString
        let timeoutResult = CommandRunner.swift(run: TestCode.InfiniteLoop, id: timeoutId, timeout: 10.0)
        print("[3/3] Exit Code: \(timeoutResult.statusCode) | \(timeoutResult.result)\n\n")

        exit(0)
    }
}

class CommandRunner {
    let tasks: [Process]
    var isRunning: Bool { return !(tasks.filter { $0.isRunning }).isEmpty }

    init(_ commands: [Command]) {
        tasks = commands.map {
            let task = Process()
            task.launchPath = $0.launchPath
            task.arguments = $0.arguments
            task.standardOutput = Pipe()
            return task
        }
    }

    func terminate() {
        tasks.forEach { task in task.terminate() }
    }

    @discardableResult
    func execute() -> Output {
        guard tasks.count > 0 else { return Output(statusCode: 1, result: Messages.NoOutput) }
        guard tasks.count != 1 else { return tasks[0].execute() }

        let taskCount: Int = tasks.count
        var output: Output = Output(statusCode: 0, result: "")

        for index in 0 ..< taskCount {
            let task = tasks[index]

            if index < (taskCount - 1) {
                tasks[index + 1].standardInput = task.standardOutput
                task.launch()
                task.waitUntilExit()
            } else {
                output = task.execute()
                guard output.statusCode == 0 else { return output }
            }
        }

        return output
    }
}

extension Process {
    func execute() -> Output {
        launch()

        guard let stdout: AnyObject = standardOutput as AnyObject? else {
            return Output(statusCode: 1, result: Messages.NoOutput)
        }

        let data: Data = stdout.fileHandleForReading.readDataToEndOfFile()
        waitUntilExit()

        guard let output: String = String(data: data, encoding: String.Encoding.utf8) else {
            return Output(statusCode: 1, result: Messages.NoOutput)
        }

        return Output(
            statusCode: Int(terminationStatus),
            result: output.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

struct Messages {
    static let Error: String = "This code either has one or more compiler errors, or does not print any output to the console.\n\nCheck your code and try again?"
    static let NoOutput: String = "Code did not produce any output. Did you add a print statement?"
    static let TimedOut: String = "Code did not return within a reasonable time. Check your code and try again."
}

struct TestCode {
    static let LiteralParam: String =
        """
        let text: String = “This is a test”

        let result = String(text.unicodeScalars.enumerated().map { Character(UnicodeScalar($0.1.value + (UInt32($0.0) + 1))!) })

        print(result)
        """

    static let InfiniteLoop: String =
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

    static let BasicPrint: String =
        """
        import Foundation

        func tester(_ string: String) -> String {
            return "Test Success: \\(string)"
        }

        let test: String = "SwiftCodeRunner"

        print(tester(test))
        """
}
