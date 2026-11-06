import Foundation

enum MachOArchitecture {
    static let process: String = {
        #if arch(arm64)
        return "arm64"
        #elseif arch(x86_64)
        return "x86_64"
        #else
        return "unknown"
        #endif
    }()

    static func names(at url: URL) -> [String] {
        guard let data = try? Data(contentsOf: url, options: [.mappedIfSafe]) else { return [] }
        return names(in: data)
    }

    static func names(in data: Data) -> [String] {
        guard data.count >= 8 else { return [] }
        let big = read32(data, 0, littleEndian: false)
        if big == 0xCAFEBABE {
            return fatNames(data, entrySize: 20)
        }
        if big == 0xCAFEBABF {
            return fatNames(data, entrySize: 32)
        }
        let little = read32(data, 0, littleEndian: true)
        if little == 0xFEEDFACF || little == 0xFEEDFACE {
            return [label(read32(data, 4, littleEndian: true))].compactMap { $0 }
        }
        return []
    }

    static func warning(executableArchitectures: [String], processArchitecture: String) -> String? {
        guard !executableArchitectures.isEmpty, processArchitecture != "unknown" else { return nil }
        guard !executableArchitectures.contains(processArchitecture) else { return nil }
        return L10n.format(
            "The scanner program is built for %@, but Samsung Scan is running as %@.",
            executableArchitectures.joined(separator: ", "),
            processArchitecture
        )
    }

    private static func fatNames(_ data: Data, entrySize: Int) -> [String] {
        let count = Int(read32(data, 4, littleEndian: false))
        guard count > 0, count < 32 else { return [] }
        var names: [String] = []
        for index in 0..<count {
            let offset = 8 + index * entrySize
            guard offset + 4 <= data.count else { break }
            if let name = label(read32(data, offset, littleEndian: false)) {
                names.append(name)
            }
        }
        return names
    }

    private static func label(_ cpu: UInt32) -> String? {
        switch cpu {
        case 0x01000007: "x86_64"
        case 0x00000007: "i386"
        case 0x0100000C: "arm64"
        case 0x0000000C: "arm"
        default: nil
        }
    }

    private static func read32(_ data: Data, _ offset: Int, littleEndian: Bool) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        let bytes = data[offset..<(offset + 4)]
        let value = bytes.enumerated().reduce(UInt32(0)) { partial, item in
            partial | (UInt32(item.element) << (UInt32(item.offset) * 8))
        }
        return littleEndian ? value : value.byteSwapped
    }
}
