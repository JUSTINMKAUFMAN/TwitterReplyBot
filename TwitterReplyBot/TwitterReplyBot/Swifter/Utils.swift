import Foundation

func rotateLeft(_ v: UInt16, n: UInt16) -> UInt16 {
    return ((v << n) & 0xFFFF) | (v >> (16 - n))
}

func rotateLeft(_ v: UInt32, n: UInt32) -> UInt32 {
    return ((v << n) & 0xFFFF_FFFF) | (v >> (32 - n))
}

func rotateLeft(_ x: UInt64, n: UInt64) -> UInt64 {
    return (x << n) | (x >> (64 - n))
}

func rotateRight(_ x: UInt16, n: UInt16) -> UInt16 {
    return (x >> n) | (x << (16 - n))
}

func rotateRight(_ x: UInt32, n: UInt32) -> UInt32 {
    return (x >> n) | (x << (32 - n))
}

func rotateRight(_ x: UInt64, n: UInt64) -> UInt64 {
    return ((x >> n) | (x << (64 - n)))
}

func reverseBytes(_ value: UInt32) -> UInt32 {
    let tmp1 = ((value & 0x0000_00FF) << 24) | ((value & 0x0000_FF00) << 8)
    let tmp2 = ((value & 0x00FF_0000) >> 8) | ((value & 0xFF00_0000) >> 24)
    return tmp1 | tmp2
}
