import Foundation

/// Parser for the human-readable part of a BOLT #11 invoice
struct HumanReadablePartParser {
    struct ParsedHRP {
        let network: Network
        let amount: Amount?
    }
    
    /// Parse the human-readable part
    /// - Parameter hrp: The HRP string (e.g., "lnbc2500u")
    /// - Returns: Parsed network and amount
    static func parse(_ hrp: String) throws -> ParsedHRP {
        // HRP must start with "ln"
        guard hrp.hasPrefix("ln") else {
            throw Bolt11Error.unsupportedNetwork(hrp)
        }
        
        // Find where the network prefix ends
        // Network prefixes: bc, tb, tbs, bcrt
        var networkPrefix = ""
        var remainingHRP = String(hrp.dropFirst(2)) // Drop "ln"
        
        // Try to match network prefixes (longest first)
        let networkPrefixes = ["bcrt", "tbs", "bc", "tb"]
        for prefix in networkPrefixes {
            if remainingHRP.hasPrefix(prefix) {
                networkPrefix = prefix
                remainingHRP = String(remainingHRP.dropFirst(prefix.count))
                break
            }
        }
        
        guard let network = Network(rawValue: networkPrefix) else {
            throw Bolt11Error.unsupportedNetwork(hrp)
        }
        
        // Parse amount if present
        let amount: Amount?
        if remainingHRP.isEmpty {
            amount = nil
        } else {
            amount = try parseAmount(remainingHRP)
        }
        
        return ParsedHRP(network: network, amount: amount)
    }
    
    /// Parse an amount string
    private static func parseAmount(_ amountString: String) throws -> Amount {
        guard !amountString.isEmpty else {
            throw Bolt11Error.invalidAmount
        }
        
        // Check for multiplier at the end
        let lastChar = amountString.last!
        let multiplier = Multiplier(rawValue: lastChar)
        
        let numericPart: String
        if multiplier != nil {
            numericPart = String(amountString.dropLast())
        } else {
            numericPart = amountString
            // Check if last character is a letter but not a valid multiplier
            if lastChar.isLetter {
                throw Bolt11Error.invalidMultiplier(lastChar)
            }
        }
        
        // Validate numeric part
        guard !numericPart.isEmpty else {
            throw Bolt11Error.invalidAmount
        }
        
        // Check for leading zeros
        if numericPart.hasPrefix("0") && numericPart.count > 1 {
            throw Bolt11Error.amountLeadingZeros
        }
        
        // Parse the numeric value
        guard let value = UInt64(numericPart) else {
            throw Bolt11Error.invalidAmount
        }
        
        // Special validation for pico multiplier
        if multiplier == .pico {
            // Last decimal of amount must be 0 for pico
            let lastDigit = numericPart.last!
            if lastDigit != "0" {
                throw Bolt11Error.invalidPicoAmount
            }
        }
        
        return Amount(value: value, multiplier: multiplier)
    }
}

