import Foundation

infix operator ??=: AssignmentPrecedence

func ??= <T>(lhs: inout T?, rhs: T?) {
    guard let rhs = rhs else { return }
    lhs = rhs
}
