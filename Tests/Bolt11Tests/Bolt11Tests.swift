import XCTest
@testable import Bolt11

final class Bolt11Tests: XCTestCase {
    
    // MARK: - Valid Invoice Tests
    
    func testDonationInvoice() throws {
        let invoiceString = "lnbc1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpl2pkx2ctnv5sxxmmwwd5kgetjypeh2ursdae8g6twvus8g6rfwvs8qun0dfjkxaq9qrsgq357wnc5r2ueh7ck6q93dj32dlqnls087fxdwk8qakdyafkq3yap9us6v52vjjsrvywa6rt52cm9r9zqt8r2t7mlcwspyetp5h2tztugp9lfyql"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertNil(invoice.amount) // No amount specified (donation)
        XCTAssertEqual(invoice.timestamp, 1496314658)
        
        // Payment hash: 0001020304050607080900010203040506070809000102030405060708090102
        let expectedHash = Data([
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
            0x08, 0x09, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05,
            0x06, 0x07, 0x08, 0x09, 0x00, 0x01, 0x02, 0x03,
            0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x01, 0x02
        ])
        XCTAssertEqual(invoice.paymentHash, expectedHash)
        
        // Payment secret: 1111111111111111111111111111111111111111111111111111111111111111
        let expectedSecret = Data(repeating: 0x11, count: 32)
        XCTAssertEqual(invoice.paymentSecret, expectedSecret)
        
        XCTAssertEqual(invoice.invoiceDescription, "Please consider supporting this project")
        XCTAssertNil(invoice.descriptionHash)
        
        // Expected public key
        let expectedPubkey = Data([
            0x03, 0xe7, 0x15, 0x6a, 0xe3, 0x3b, 0x0a, 0x20,
            0x8d, 0x07, 0x44, 0x19, 0x91, 0x63, 0x17, 0x7e,
            0x90, 0x9e, 0x80, 0x17, 0x6e, 0x55, 0xd9, 0x7a,
            0x2f, 0x22, 0x1e, 0xde, 0x0f, 0x93, 0x4d, 0xd9, 0xad
        ])
        XCTAssertEqual(invoice.payeePublicKey, expectedPubkey)
        
        XCTAssertEqual(invoice.expiryTime, 3600) // default
        XCTAssertEqual(invoice.minFinalCltvExpiry, 18) // default
    }
    
    func testCoffeeInvoice() throws {
        let invoiceString = "lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        
        // Amount: 2500 micro-bitcoin
        XCTAssertNotNil(invoice.amount)
        XCTAssertEqual(invoice.amount?.value, 2500)
        XCTAssertEqual(invoice.amount?.multiplier, .micro)
        XCTAssertEqual(invoice.amountMillisatoshis, 250_000_000) // 2500 * 100,000
        
        XCTAssertEqual(invoice.timestamp, 1496314658)
        XCTAssertEqual(invoice.invoiceDescription, "1 cup coffee")
        XCTAssertEqual(invoice.expiryTime, 60) // 1 minute
    }
    
    func testNonsenseInvoice() throws {
        let invoiceString = "lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpu9qrsgqhtjpauu9ur7fw2thcl4y9vfvh4m9wlfyz2gem29g5ghe2aak2pm3ps8fdhtceqsaagty2vph7utlgj48u0ged6a337aewvraedendscp573dxr"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertEqual(invoice.amount?.value, 2500)
        XCTAssertEqual(invoice.amount?.multiplier, .micro)
        XCTAssertEqual(invoice.invoiceDescription, "ナンセンス 1杯") // UTF-8 Japanese text
        XCTAssertEqual(invoice.expiryTime, 60)
    }
    
    func testHashedDescriptionInvoice() throws {
        let invoiceString = "lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs9qrsgq7ea976txfraylvgzuxs8kgcw23ezlrszfnh8r6qtfpr6cxga50aj6txm9rxrydzd06dfeawfk6swupvz4erwnyutnjq7x39ymw6j38gp7ynn44"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertEqual(invoice.amount?.value, 20)
        XCTAssertEqual(invoice.amount?.multiplier, .milli)
        
        XCTAssertNil(invoice.invoiceDescription)
        XCTAssertNotNil(invoice.descriptionHash)
        
        // Expected hash of long description
        let expectedHash = Data([
            0x39, 0x25, 0xb6, 0xf6, 0x7e, 0x2c, 0x34, 0x00,
            0x36, 0xed, 0x12, 0x09, 0x3d, 0xd4, 0x4e, 0x03,
            0x68, 0xdf, 0x1b, 0x6e, 0xa2, 0x6c, 0x53, 0xdb,
            0xe4, 0x81, 0x1f, 0x58, 0xfd, 0x5d, 0xb8, 0xc1
        ])
        XCTAssertEqual(invoice.descriptionHash, expectedHash)
    }
    
    func testTestnetFallbackInvoice() throws {
        let invoiceString = "lntb20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygshp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqfpp3x9et2e20v6pu37c5d9vax37wxq72un989qrsgqdj545axuxtnfemtpwkc45hx9d2ft7x04mt8q7y6t0k2dge9e7h8kpy9p34ytyslj3yu569aalz2xdk8xkd7ltxqld94u8h2esmsmacgpghe9k8"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .testnet)
        XCTAssertEqual(invoice.amount?.value, 20)
        XCTAssertEqual(invoice.amount?.multiplier, .milli)
        
        XCTAssertEqual(invoice.fallbackAddresses.count, 1)
        let fallback = invoice.fallbackAddresses[0]
        XCTAssertEqual(fallback.version, 17) // P2PKH
    }
    
    func testRoutingInfoInvoice() throws {
        let invoiceString = "lnbc20m1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqsfpp3qjmp7lwpagxun9pygexvgpjdc4jdj85fr9yq20q82gphp2nflc7jtzrcazrra7wwgzxqc8u7754cdlpfrmccae92qgzqvzq2ps8pqqqqqqpqqqqq9qqqvpeuqafqxu92d8lr6fvg0r5gv0heeeqgcrqlnm6jhphu9y00rrhy4grqszsvpcgpy9qqqqqqgqqqqq7qqzq9qrsgqdfjcdk6w3ak5pca9hwfwfh63zrrz06wwfya0ydlzpgzxkn5xagsqz7x9j4jwe7yj7vaf2k9lqsdk45kts2fd0fkr28am0u4w95tt2nsq76cqw0"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertEqual(invoice.routingHints.count, 1)
        
        let route = invoice.routingHints[0]
        XCTAssertEqual(route.hops.count, 2)
        
        // First hop
        let hop1 = route.hops[0]
        XCTAssertEqual(hop1.publicKey.count, 33)
        XCTAssertEqual(hop1.shortChannelId, 66051 << 40 | 263430 << 16 | 1800)
        XCTAssertEqual(hop1.feeBaseMsat, 1)
        XCTAssertEqual(hop1.feeProportionalMillionths, 20)
        XCTAssertEqual(hop1.cltvExpiryDelta, 3)
    }
    
    func testUpperCaseInvoice() throws {
        let invoiceString = "LNBC25M1PVJLUEZPP5QQQSYQCYQ5RQWZQFQQQSYQCYQ5RQWZQFQQQSYQCYQ5RQWZQFQYPQDQ5VDHKVEN9V5SXYETPDEESSP5ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYG3ZYGS9Q5SQQQQQQQQQQQQQQQQSGQ2A25DXL5HRNTDTN6ZVYDT7D66HYZSYHQS4WDYNAVYS42XGL6SGX9C4G7ME86A27T07MDTFRY458RTJR0V92CNMSWPSJSCGT2VCSE3SGPZ3UAPA"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertEqual(invoice.amount?.value, 25)
        XCTAssertEqual(invoice.amount?.multiplier, .milli)
        XCTAssertEqual(invoice.invoiceDescription, "coffee beans")
    }
    
    func testPicoAmountInvoice() throws {
        let invoiceString = "lnbc9678785340p1pwmna7lpp5gc3xfm08u9qy06djf8dfflhugl6p7lgza6dsjxq454gxhj9t7a0sd8dgfkx7cmtwd68yetpd5s9xar0wfjn5gpc8qhrsdfq24f5ggrxdaezqsnvda3kkum5wfjkzmfqf3jkgem9wgsyuctwdus9xgrcyqcjcgpzgfskx6eqf9hzqnteypzxz7fzypfhg6trddjhygrcyqezcgpzfysywmm5ypxxjemgw3hxjmn8yptk7untd9hxwg3q2d6xjcmtv4ezq7pqxgsxzmnyyqcjqmt0wfjjq6t5v4khxsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygsxqyjw5qcqp2rzjq0gxwkzc8w6323m55m4jyxcjwmy7stt9hwkwe2qxmy8zpsgg7jcuwz87fcqqeuqqqyqqqqlgqqqqn3qq9q9qrsgqrvgkpnmps664wgkp43l22qsgdw4ve24aca4nymnxddlnp8vh9v2sdxlu5ywdxefsfvm0fq3sesf08uf6q9a2ke0hc9j6z6wlxg5z5kqpu2v9wz"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertEqual(invoice.amount?.value, 9678785340)
        XCTAssertEqual(invoice.amount?.multiplier, .pico)
        
        // 9678785340 pico-bitcoin = 967878534 milli-satoshi
        XCTAssertEqual(invoice.amountMillisatoshis, 967878534)
        
        XCTAssertNotNil(invoice.invoiceDescription)
        XCTAssertEqual(invoice.expiryTime, 604800) // 1 week
    }
    
    func testPaymentMetadataInvoice() throws {
        let invoiceString = "lnbc10m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdp9wpshjmt9de6zqmt9w3skgct5vysxjmnnd9jx2mq8q8a04uqsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygs9q2gqqqqqqsgq7hf8he7ecf7n4ffphs6awl9t6676rrclv9ckg3d3ncn7fct63p6s365duk5wrk202cfy3aj5xnnp5gs3vrdvruverwwq7yzhkf5a3xqpd05wjc"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertEqual(invoice.amount?.value, 10)
        XCTAssertEqual(invoice.amount?.multiplier, .milli)
        XCTAssertNotNil(invoice.metadata)
        
        // Metadata: 0x01fafaf0
        let expectedMetadata = Data([0x01, 0xfa, 0xfa, 0xf0])
        XCTAssertEqual(invoice.metadata, expectedMetadata)
    }
    
    // MARK: - Invalid Invoice Tests
    
    func testInvalidChecksum() {
        let invoiceString = "lnbc2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpuyk0sg5g70me25alkluzd2x62aysf2pyy8edtjeevuv4p2d5p76r4zkmneet7uvyakky2zr4cusd45tftc9c5fh0nnqpnl2jfll544esqchsrnt"
        
        XCTAssertThrowsError(try Bolt11Decoder.decode(invoiceString)) { error in
            XCTAssertEqual(error as? Bolt11Error, .invalidChecksum)
        }
    }
    
    func testNoSeparator() {
        let invoiceString = "pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpuyk0sg5g70me25alkluzd2x62aysf2pyy8edtjeevuv4p2d5p76r4zkmneet7uvyakky2zr4cusd45tftc9c5fh0nnqpnl2jfll544esqchsrny"
        
        XCTAssertThrowsError(try Bolt11Decoder.decode(invoiceString)) { error in
            XCTAssertEqual(error as? Bolt11Error, .noSeparator)
        }
    }
    
    func testMixedCase() {
        let invoiceString = "LNBC2500u1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdpquwpc4curk03c9wlrswe78q4eyqc7d8d0xqzpuyk0sg5g70me25alkluzd2x62aysf2pyy8edtjeevuv4p2d5p76r4zkmneet7uvyakky2zr4cusd45tftc9c5fh0nnqpnl2jfll544esqchsrny"
        
        XCTAssertThrowsError(try Bolt11Decoder.decode(invoiceString)) { error in
            XCTAssertEqual(error as? Bolt11Error, .mixedCase)
        }
    }
    
    func testInvalidMultiplier() {
        let invoiceString = "lnbc2500x1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpusp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygs9qrsgqrrzc4cvfue4zp3hggxp47ag7xnrlr8vgcmkjxk3j5jqethnumgkpqp23z9jclu3v0a7e0aruz366e9wqdykw6dxhdzcjjhldxq0w6wgqcnu43j"
        
        XCTAssertThrowsError(try Bolt11Decoder.decode(invoiceString)) { error in
            XCTAssertEqual(error as? Bolt11Error, .invalidMultiplier("x"))
        }
    }
    
    func testSubMillisatoshiPrecision() {
        let invoiceString = "lnbc2500000001p1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpusp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygs9qrsgq0lzc236j96a95uv0m3umg28gclm5lqxtqqwk32uuk4k6673k6n5kfvx3d2h8s295fad45fdhmusm8sjudfhlf6dcsxmfvkeywmjdkxcp99202x"
        
        XCTAssertThrowsError(try Bolt11Decoder.decode(invoiceString)) { error in
            XCTAssertEqual(error as? Bolt11Error, .invalidPicoAmount)
        }
    }
    
    func testMissingPaymentSecret() {
        let invoiceString = "lnbc20m1pvjluezpp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqhp58yjmdan79s6qqdhdzgynm4zwqd5d7xmw5fk98klysy043l2ahrqs9qrsgq7ea976txfraylvgzuxs8kgcw23ezlrszfnh8r6qtfpr6cxga50aj6txm9rxrydzd06dfeawfk6swupvz4erwnyutnjq7x39ymw6j38gp49qdkj"
        
        XCTAssertThrowsError(try Bolt11Decoder.decode(invoiceString)) { error in
            XCTAssertEqual(error as? Bolt11Error, .missingRequiredField("s"))
        }
    }
    
    // MARK: - Helper Tests
    
    func testIsExpired() throws {
        let invoiceString = "lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh"
        
        let invoice = try Bolt11Decoder.decode(invoiceString)
        
        // This invoice is from 2017, so it should be expired
        XCTAssertTrue(invoice.isExpired())
        
        // But not expired at creation time
        let creationDate = Date(timeIntervalSince1970: TimeInterval(invoice.timestamp))
        XCTAssertFalse(invoice.isExpired(at: creationDate))
    }
    
    func testStringExtension() throws {
        let invoiceString = "lnbc2500u1pvjluezsp5zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zyg3zygspp5qqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqqqsyqcyq5rqwzqfqypqdq5xysxxatsyp3k7enxv4jsxqzpu9qrsgquk0rl77nj30yxdy8j9vdx85fkpmdla2087ne0xh8nhedh8w27kyke0lp53ut353s06fv3qfegext0eh0ymjpf39tuven09sam30g4vgpfna3rh"
        
        let invoice = try invoiceString.decodeBolt11()
        
        XCTAssertEqual(invoice.network, .mainnet)
        XCTAssertEqual(invoice.originalString, invoiceString)
    }
    
    func testPrintDecoded() throws {
        let invoiceString = "lnbc5550n1p500wd5sp5mrvutt7pawqtwnmfa809chysp5f2uqa0fjgu3xwdzu05gsz7jfpqpp508mgwhhrkkkqj8s4l0jfrknnwf5q4l69x33gh7rt63y72nxa0ymqdqqcqpjrzjq29jmvsu7ml3fz7g3rdlmklxmk48mvw9wfy8hjjhwd5s5fplflfg6rw9hcqqkhcqqqqqqqlgqqqqraqqjq9qxpqysgqveztw3vvhv4spu72lfeqkc9pcuc5ur2nz0k7420338kfrgq383mrlca2m23zjegjva9cd5zfhaytfe0pjt3gmn2vev5he6r7ygkqh9qqmyapk6"
        
        let invoice = try invoiceString.decodeBolt11()
        
        print(invoice.prettyPrint)
    }
}
