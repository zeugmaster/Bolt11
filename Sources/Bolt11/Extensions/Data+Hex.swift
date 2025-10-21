import Foundation

extension Data {
    /// Convert data to a hexadecimal string
    public var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
    
    /// Initialize from a hexadecimal string
    /// - Parameter hex: Hexadecimal string (with or without "0x" prefix)
    public init?(hexString: String) {
        let hex = hexString.hasPrefix("0x") ? String(hexString.dropFirst(2)) : hexString
        
        guard hex.count % 2 == 0 else {
            return nil
        }
        
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            let byteString = hex[index..<nextIndex]
            
            guard let byte = UInt8(byteString, radix: 16) else {
                return nil
            }
            
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
}

