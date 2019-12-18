import Foundation

protocol Module {
    var handle: String { get }
    var thread: String? { get }
    var blacklist: [String] { get }

    func output(for reply: Reply, _ completion: @escaping ((String) -> Void))
    func validate()

    init()
}

extension Module {
    var thread: String? { return nil }
    var blacklist: [String] { return [] }
    func validate() { assert(true) }
}
