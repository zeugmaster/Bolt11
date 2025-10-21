import Foundation

/// Lightning Network type
public enum Network: String, Equatable {
    case mainnet = "bc"
    case testnet = "tb"
    case signet = "tbs"
    case regtest = "bcrt"
    
    /// Full prefix including 'ln'
    public var prefix: String {
        return "ln" + rawValue
    }
    
    /// Initialize from a prefix string (e.g., "lnbc", "lntb")
    public init?(prefix: String) {
        guard prefix.hasPrefix("ln") else {
            return nil
        }
        let networkPart = String(prefix.dropFirst(2))
        self.init(rawValue: networkPart)
    }
}

