//
//  Base32Tests.swift
//  Base32
//
//  Created by 野村 憲男 on 1/24/15.
//  Copyright (c) 2015 Norio Nomura. All rights reserved.
//

import Foundation
import XCTest
import Base32

class Base32Tests: XCTestCase {
    
    let vectors: [(String,String,String)] = [
        ("", "", ""),
        ("f", "MY======", "CO======"),
        ("fo", "MZXQ====", "CPNG===="),
        ("foo", "MZXW6===", "CPNMU==="),
        ("foob", "MZXW6YQ=", "CPNMUOG="),
        ("fooba", "MZXW6YTB", "CPNMUOJ1"),
        ("foobar", "MZXW6YTBOI======", "CPNMUOJ1E8======"),
    ]
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: https://tools.ietf.org/html/rfc4648
    
    func test_RFC4648_base32Encode() {
        let convertedVectors = self.vectors.map {($0.dataUsingUTF8StringEncoding, $1, $2)}
        self.measureBlock{
            for _ in 0...100 {
                for (test, expect, _) in convertedVectors {
                    let result = base32Encode(test)
                    XCTAssertEqual(result, expect, "base32Encode for \(test)")
                }
            }
        }
    }
    
    func test_RFC4648_base32Decode() {
        let convertedVectors = self.vectors.map {($0.dataUsingUTF8StringEncoding, $1, $2)}
        self.measureBlock{
            for _ in 0...100 {
                for (expect, test, _) in convertedVectors {
                    let result = base32DecodeToData(test)
                    XCTAssertEqual(result!, expect, "base32Decode for \(test)")
                }
            }
        }
    }
    
    func test_RFC4648_base32HexEncode() {
        let convertedVectors = self.vectors.map {($0.dataUsingUTF8StringEncoding, $1, $2)}
        self.measureBlock{
            for _ in 0...100 {
                for (test, _, expectHex) in convertedVectors {
                    let resultHex = base32HexEncode(test)
                    XCTAssertEqual(resultHex, expectHex, "base32HexEncode for \(test)")
                }
            }
        }
    }
    
    func test_RFC4648_base32HexDecode() {
        let convertedVectors = self.vectors.map {($0.dataUsingUTF8StringEncoding, $1, $2)}
        self.measureBlock{
            for _ in 0...100 {
                for (expect, _, testHex) in convertedVectors {
                    let resultHex = base32HexDecodeToData(testHex)
                    XCTAssertEqual(resultHex!, expect, "base32HexDecode for \(testHex)")
                }
            }
        }
    }
    
    // MARK: -
    
    func test_base32ExtensionString() {
        self.measureBlock{
            for _ in 0...100 {
                for (test, expect, expectHex) in self.vectors {
                    let result = test.base32EncodedString
                    let resultHex = test.base32HexEncodedString
                    XCTAssertEqual(result, expect, "\(test).base32EncodedString")
                    XCTAssertEqual(resultHex, expectHex, "\(test).base32HexEncodedString")
                    let decoded = result.base32DecodedString()
                    let decodedHex = resultHex.base32HexDecodedString()
                    XCTAssertEqual(decoded!, test, "\(result).base32DecodedString()")
                    XCTAssertEqual(decodedHex!, test, "\(resultHex).base32HexDecodedString()")
                }
            }
        }
    }
    
    func test_base32ExtensionData() {
        let dataVectors = vectors.map {
            (
                $0.dataUsingUTF8StringEncoding,
                $1.dataUsingUTF8StringEncoding,
                $2.dataUsingUTF8StringEncoding
            )
        }
        self.measureBlock{
            for _ in 0...100 {
                for (test, expect, expectHex) in dataVectors {
                    let result = test.base32EncodedData
                    let resultHex = test.base32HexEncodedData
                    XCTAssertEqual(result, expect, "\(test).base32EncodedData")
                    XCTAssertEqual(resultHex, expectHex, "\(test).base32HexEncodedData")
                    let decoded = result.base32DecodedData
                    let decodedHex = resultHex.base32HexDecodedData
                    XCTAssertEqual(decoded!, test, "\(result).base32DecodedData")
                    XCTAssertEqual(decodedHex!, test, "\(resultHex).base32HexDecodedData")
                }
            }
        }
    }
    
    func test_base32ExtensionDataAndString() {
        let dataAndStringVectors = vectors.map {($0.dataUsingUTF8StringEncoding, $1, $2)}
        self.measureBlock{
            for _ in 0...100 {
                for (test, expect, expectHex) in dataAndStringVectors {
                    let result = test.base32EncodedString
                    let resultHex = test.base32HexEncodedString
                    XCTAssertEqual(result, expect, "\(test).base32EncodedString")
                    XCTAssertEqual(resultHex, expectHex, "\(test).base32HexEncodedString")
                    let decoded = result.base32DecodedData
                    let decodedHex = resultHex.base32HexDecodedData
                    XCTAssertEqual(decoded!, test, "\(result).base32DecodedData")
                    XCTAssertEqual(decodedHex!, test, "\(resultHex).base32HexDecodedData")
                }
            }
        }
    }
    
    // MARK:
    
    func test_base32DecodeStringAcceptableLengthPatterns() {
        // "=" stripped valid string
        let strippedVectors = vectors.map {
            (
                $0.dataUsingUTF8StringEncoding,
                $1.stringByReplacingOccurrencesOfString("=", withString:""),
                $2.stringByReplacingOccurrencesOfString("=", withString:"")
            )
        }
        for (expect, test, testHex) in strippedVectors {
            let result = base32DecodeToData(test)
            let resultHex = base32HexDecodeToData(testHex)
            XCTAssertEqual(result!, expect, "base32Decode for \(test)")
            XCTAssertEqual(resultHex!, expect, "base32HexDecode for \(testHex)")
        }
        
        // invalid length string with padding
        let invalidVectorWithPaddings: [(String,String)] = [
            ("M=======", "C======="),
            ("MYZ=====", "COZ====="),
            ("MZXW6Z==", "CPNMUZ=="),
            ("MZXW6YTBO=======", "CPNMUOJ1E======="),
        ]
        for (test, testHex) in invalidVectorWithPaddings {
            let result = base32DecodeToData(test)
            let resultHex = base32HexDecodeToData(testHex)
            XCTAssertNil(result, "base32Decode for \(test)")
            XCTAssertNil(resultHex, "base32HexDecode for \(test)")
        }
        
        // invalid length string without padding
        _ = invalidVectorWithPaddings.map {
            (
                $0.stringByReplacingOccurrencesOfString("=", withString:""),
                $1.stringByReplacingOccurrencesOfString("=", withString:"")
            )
        }
        for (test, testHex) in invalidVectorWithPaddings {
            let result = base32DecodeToData(test)
            let resultHex = base32HexDecodeToData(testHex)
            XCTAssertNil(result, "base32Decode for \(test)")
            XCTAssertNil(resultHex, "base32HexDecode for \(test)")
        }
    }
}
