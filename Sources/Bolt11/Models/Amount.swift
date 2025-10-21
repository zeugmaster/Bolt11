import Foundation

/// Multiplier for Lightning invoice amounts
public enum Multiplier: Character {
    case milli = "m"    // 0.001
    case micro = "u"    // 0.000001
    case nano = "n"     // 0.000000001
    case pico = "p"     // 0.000000000001
    
    /// Multiplier value relative to the base currency
    public var value: Decimal {
        switch self {
        case .milli: return 0.001
        case .micro: return 0.000001
        case .nano: return 0.000000001
        case .pico: return 0.000000000001
        }
    }
    
    /// Conversion factor to millisatoshis (for Bitcoin)
    /// 1 BTC = 100,000,000 satoshi = 100,000,000,000 millisatoshi
    public var millisatoshiFactor: Decimal {
        switch self {
        case .milli: return 100_000_000    // 1 mBTC = 100,000,000 msat
        case .micro: return 100_000        // 1 µBTC = 100,000 msat
        case .nano: return 100             // 1 nBTC = 100 msat
        case .pico: return 0.1             // 1 pBTC = 0.1 msat (sub-millisat)
        }
    }
}

/// Amount in a Lightning invoice
public struct Amount: Equatable {
    /// The numeric value
    public let value: UInt64
    
    /// The multiplier (if any)
    public let multiplier: Multiplier?
    
    /// Amount in millisatoshis
    /// Returns nil if the amount would be sub-millisatoshi (pico with non-zero trailing digit)
    public var millisatoshis: UInt64? {
        guard let multiplier = multiplier else {
            // No multiplier means the value is in the base unit (BTC)
            // 1 BTC = 100,000,000,000 millisatoshi
            return value * 100_000_000_000
        }
        
        let factor = multiplier.millisatoshiFactor
        let decimalValue = Decimal(value) * factor
        
        // Check if it's a whole number of millisatoshis
        guard decimalValue.isWholeNumber else {
            return nil
        }
        
        return UInt64(truncating: decimalValue as NSNumber)
    }
    
    public init(value: UInt64, multiplier: Multiplier?) {
        self.value = value
        self.multiplier = multiplier
    }
}

extension Decimal {
    var isWholeNumber: Bool {
        let rounded = NSDecimalNumber(decimal: self).rounding(accordingToBehavior: NSDecimalNumberHandler(roundingMode: .plain, scale: 0, raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false, raiseOnDivideByZero: false))
        return self == rounded.decimalValue
    }
}

