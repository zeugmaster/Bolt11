import Foundation
import secp256k1

/// Validates ECDSA signatures using secp256k1
struct SignatureValidator {
    /// Verify a signature and recover the public key
    /// - Parameters:
    ///   - signature: The 64-byte signature (r, s)
    ///   - recoveryId: The recovery ID (0-3)
    ///   - messageHash: The 32-byte message hash
    /// - Returns: The recovered 33-byte public key (compressed)
    static func recoverPublicKey(signature: Data, recoveryId: UInt8, messageHash: Data) throws -> Data {
        guard signature.count == 64 else {
            throw Bolt11Error.invalidSignature
        }
        
        guard messageHash.count == 32 else {
            throw Bolt11Error.invalidSignature
        }
        
        guard recoveryId < 4 else {
            throw Bolt11Error.invalidSignature
        }
        
        // Create context
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY)) else {
            throw Bolt11Error.invalidSignature
        }
        defer {
            secp256k1_context_destroy(context)
        }
            
        // Parse the recoverable signature
        var recovarableSignature = secp256k1_ecdsa_recoverable_signature()
        var signatureBytes = [UInt8](signature)
        
        guard secp256k1_ecdsa_recoverable_signature_parse_compact(
            context,
            &recovarableSignature,
            &signatureBytes,
            Int32(recoveryId)
        ) == 1 else {
            throw Bolt11Error.invalidSignature
        }
        
        // Recover the public key
        var publicKeyObj = secp256k1_pubkey()
        var messageHashBytes = [UInt8](messageHash)
        
        guard secp256k1_ecdsa_recover(
            context,
            &publicKeyObj,
            &recovarableSignature,
            &messageHashBytes
        ) == 1 else {
            throw Bolt11Error.signatureNotRecoverable
        }
        
        // Serialize the public key in compressed format
        var publicKeyBytes = [UInt8](repeating: 0, count: 33)
        var outputLen = 33
        
        guard secp256k1_ec_pubkey_serialize(
            context,
            &publicKeyBytes,
            &outputLen,
            &publicKeyObj,
            UInt32(SECP256K1_EC_COMPRESSED)
        ) == 1 else {
            throw Bolt11Error.invalidPublicKey
        }
        
        return Data(publicKeyBytes)
    }
    
    /// Verify a signature against a known public key
    /// - Parameters:
    ///   - signature: The 64-byte signature (r, s)
    ///   - messageHash: The 32-byte message hash
    ///   - publicKey: The 33-byte compressed public key
    /// - Returns: True if the signature is valid
    static func verifySignature(signature: Data, messageHash: Data, publicKey: Data) -> Bool {
        guard signature.count == 64 else {
            return false
        }
        
        guard messageHash.count == 32 else {
            return false
        }
        
        guard publicKey.count == 33 else {
            return false
        }
        
        guard let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY)) else {
            return false
        }
        defer {
            secp256k1_context_destroy(context)
        }
        
        // Parse the public key
        var publicKeyObj = secp256k1_pubkey()
        var publicKeyBytes = [UInt8](publicKey)
        
        guard secp256k1_ec_pubkey_parse(
            context,
            &publicKeyObj,
            &publicKeyBytes,
            publicKey.count
        ) == 1 else {
            return false
        }
        
        // Parse the signature (non-recoverable)
        var signatureObj = secp256k1_ecdsa_signature()
        var signatureBytes = [UInt8](signature)
        
        guard secp256k1_ecdsa_signature_parse_compact(
            context,
            &signatureObj,
            &signatureBytes
        ) == 1 else {
            return false
        }
        
        // Verify the signature
        var messageHashBytes = [UInt8](messageHash)
        
        return secp256k1_ecdsa_verify(
            context,
            &signatureObj,
            &messageHashBytes,
            &publicKeyObj
        ) == 1
    }
}

