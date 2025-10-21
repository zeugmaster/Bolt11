import Foundation

/// Main decoder for BOLT #11 Lightning invoices
public struct Bolt11Decoder {
    /// Decode a BOLT #11 Lightning invoice string
    /// - Parameter invoiceString: The invoice string (e.g., "lnbc...")
    /// - Returns: A decoded Invoice object
    /// - Throws: Bolt11Error if the invoice is invalid
    public static func decode(_ invoiceString: String) throws -> Invoice {
        // Step 1: Decode Bech32
        let decoded = try Bech32Decoder.decode(invoiceString)
        
        // Step 2: Parse human-readable part
        let hrp = try HumanReadablePartParser.parse(decoded.hrp)
        
        // Step 3: Parse data part
        let dataPart = try DataPartParser.parse(data: decoded.data, hrp: decoded.hrp)
        
        // Step 4: Validate tagged fields
        let validated = try InvoiceValidator.validateFields(dataPart.fields)
        
        // Step 5: Verify signature and recover/validate public key
        let messageHash = HashUtilities.sha256(dataPart.signingData)
        
        let finalPublicKey: Data
        if let providedPublicKey = validated.payeePublicKey {
            // If public key is provided, verify signature against it
            guard SignatureValidator.verifySignature(
                signature: dataPart.signature,
                messageHash: messageHash,
                publicKey: providedPublicKey
            ) else {
                throw Bolt11Error.invalidSignature
            }
            finalPublicKey = providedPublicKey
        } else {
            // Recover public key from signature
            finalPublicKey = try SignatureValidator.recoverPublicKey(
                signature: dataPart.signature,
                recoveryId: dataPart.recoveryId,
                messageHash: messageHash
            )
        }
        
        // Step 6: Construct the final invoice
        let invoice = Invoice(
            network: hrp.network,
            amount: hrp.amount,
            timestamp: dataPart.timestamp,
            paymentHash: validated.paymentHash,
            paymentSecret: validated.paymentSecret,
            invoiceDescription: validated.description,
            descriptionHash: validated.descriptionHash,
            payeePublicKey: finalPublicKey,
            expiryTime: validated.expiryTime,
            minFinalCltvExpiry: validated.minFinalCltvExpiry,
            fallbackAddresses: validated.fallbackAddresses,
            routingHints: validated.routingHints,
            features: validated.features,
            metadata: validated.metadata,
            signature: dataPart.signature,
            recoveryId: dataPart.recoveryId,
            originalString: invoiceString
        )
        
        return invoice
    }
}

// Convenience extension for decoding directly on String
public extension String {
    /// Decode this string as a BOLT #11 Lightning invoice
    /// - Returns: A decoded Invoice object
    /// - Throws: Bolt11Error if the invoice is invalid
    func decodeBolt11() throws -> Invoice {
        try Bolt11Decoder.decode(self)
    }
}
