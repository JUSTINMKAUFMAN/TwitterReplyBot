import Foundation

struct SHA1 {
    private var message: [UInt8]

    private let h: [UInt32] = [0x6745_2301, 0xEFCD_AB89, 0x98BA_DCFE, 0x1032_5476, 0xC3D2_E1F0]

    init(_ message: Data) {
        self.message = message.rawBytes
    }

    init(_ message: [UInt8]) {
        self.message = message
    }

    func prepare(_ message: [UInt8], _ blockSize: Int, _ allowance: Int) -> [UInt8] {
        var tmpMessage = message
        tmpMessage.append(0x80)
        var msgLength = tmpMessage.count
        var counter = 0

        while msgLength % blockSize != (blockSize - allowance) {
            counter += 1
            msgLength += 1
        }

        tmpMessage += [UInt8](repeating: 0, count: counter)
        return tmpMessage
    }

    func calculate() -> [UInt8] {
        var tmpMessage = prepare(message, 64, 64 / 8)
        var hh = h
        tmpMessage += (message.count * 8).bytes(64 / 8)

        let chunkSizeBytes = 512 / 8 // 64
        for chunk in BytesSequence(data: tmpMessage, chunkSize: chunkSizeBytes) {
            var M: [UInt32] = [UInt32](repeating: 0, count: 80)
            for x in 0 ..< M.count {
                switch x {
                case 0 ... 15:
                    let memorySize = MemoryLayout<UInt32>.size
                    let start = chunk.startIndex + (x * memorySize)
                    let end = start + memorySize
                    let le = chunk[start ..< end].toUInt32
                    M[x] = le.bigEndian
                default:
                    M[x] = rotateLeft(M[x - 3] ^ M[x - 8] ^ M[x - 14] ^ M[x - 16], n: 1)
                }
            }

            var A = hh[0], B = hh[1], C = hh[2], D = hh[3], E = hh[4]

            for j in 0 ... 79 {
                var f: UInt32 = 0
                var k: UInt32 = 0

                switch j {
                case 0 ... 19:
                    f = (B & C) | ((~B) & D)
                    k = 0x5A82_7999
                case 20 ... 39:
                    f = B ^ C ^ D
                    k = 0x6ED9_EBA1
                case 40 ... 59:
                    f = (B & C) | (B & D) | (C & D)
                    k = 0x8F1B_BCDC
                case 60 ... 79:
                    f = B ^ C ^ D
                    k = 0xCA62_C1D6
                default:
                    break
                }

                let temp = (rotateLeft(A, n: 5) &+ f &+ E &+ M[j] &+ k) & 0xFFFF_FFFF
                E = D
                D = C
                C = rotateLeft(B, n: 30)
                B = A
                A = temp
            }

            hh[0] = (hh[0] &+ A) & 0xFFFF_FFFF
            hh[1] = (hh[1] &+ B) & 0xFFFF_FFFF
            hh[2] = (hh[2] &+ C) & 0xFFFF_FFFF
            hh[3] = (hh[3] &+ D) & 0xFFFF_FFFF
            hh[4] = (hh[4] &+ E) & 0xFFFF_FFFF
        }

        var result = [UInt8]()
        result.reserveCapacity(hh.count / 4)
        hh.forEach {
            let item = $0.bigEndian
            result += [UInt8(item & 0xFF), UInt8((item >> 8) & 0xFF), UInt8((item >> 16) & 0xFF), UInt8((item >> 24) & 0xFF)]
        }

        return result
    }

    private func rotateLeft(_ v: UInt32, n: UInt32) -> UInt32 {
        return ((v << n) & 0xFFFF_FFFF) | (v >> (32 - n))
    }
}

private struct BytesSequence<D: RandomAccessCollection>: Sequence where D.Iterator.Element == UInt8, D.Index == Int {
    let data: D
    let chunkSize: Int

    func makeIterator() -> AnyIterator<D.SubSequence> {
        var offset = data.startIndex
        return AnyIterator {
            let end = Swift.min(self.chunkSize, self.data.count - offset)
            let result = self.data[offset ..< offset + end]
            offset = offset.advanced(by: result.count)
            if !result.isEmpty { return result }
            return nil
        }
    }
}

extension Collection where Self.Iterator.Element == UInt8, Self.Index == Int {
    var toUInt32: UInt32 {
        assert(count > 3)
        return toUInt32Array()[0]
    }

    func toUInt32Array() -> [UInt32] {
        var result = [UInt32]()
        result.reserveCapacity(16)
        for idx in stride(from: startIndex, to: endIndex, by: MemoryLayout<UInt32>.size) {
            var val: UInt32 = 0
            val |= count > 3 ? UInt32(self[idx.advanced(by: 3)]) << 24 : 0
            val |= count > 2 ? UInt32(self[idx.advanced(by: 2)]) << 16 : 0
            val |= count > 1 ? UInt32(self[idx.advanced(by: 1)]) << 8 : 0
            val |= count > 0 ? UInt32(self[idx]) : 0
            result.append(val)
        }

        return result
    }
}
