import Foundation

let shouldRunTests: Bool = false
let timeout: TimeInterval = 10.0
guard !shouldRunTests else { CommandRunner.runTests(); exit(0) }
guard let config = CommandRunner.config(from: CommandLine.arguments) else { print("Something went wrong. Try again?"); exit(1) }
let output: Output = CommandRunner.swift(run: config.code, id: config.id, timeout: timeout)
let result: String = output.result.trimmingCharacters(in: .whitespacesAndNewlines)
let echo: String = result.isEmpty ? Messages.Error : result
print(echo)
exit(0)
