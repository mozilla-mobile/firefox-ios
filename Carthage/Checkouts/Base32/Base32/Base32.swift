//
//  Base32.swift
//  TOTP
//
//  Created by 野村 憲男 on 1/24/15.
//  Copyright (c) 2015 Norio Nomura. All rights reserved.
//

import Foundation

// https://tools.ietf.org/html/rfc4648

// MARK: - Base32 NSData <-> String

public func base32Encode(data: NSData) -> String {
    return base32encode(data.bytes, length: data.length, table: alphabetEncodeTable)
}

public func base32HexEncode(data: NSData) -> String {
    return base32encode(data.bytes, length: data.length, table: extendedHexAlphabetEncodeTable)
}

public func base32DecodeToData(string: String) -> NSData? {
    if let array = base32decode(string, table: alphabetDecodeTable) {
        return NSData(bytes: array, length: array.count)
    } else {
        return nil
    }
}

public func base32HexDecodeToData(string: String) -> NSData? {
    if let array = base32decode(string, table: extendedHexAlphabetDecodeTable) {
        return NSData(bytes: array, length: array.count)
    } else {
        return nil
    }
}

// MARK: - Base32 [UInt8] <-> String

public func base32Encode(array: [UInt8]) -> String {
    return base32encode(array, length: array.count, table: alphabetEncodeTable)
}

public func base32HexEncode(array: [UInt8]) -> String {
    return base32encode(array, length: array.count, table: extendedHexAlphabetEncodeTable)
}

public func base32Decode(string: String) -> [UInt8]? {
    return base32decode(string, table: alphabetDecodeTable)
}

public func base32HexDecode(string: String) -> [UInt8]? {
    return base32decode(string, table: extendedHexAlphabetDecodeTable)
}

// MARK: extensions

extension String {
    // base32
    public var base32DecodedData: NSData? {
        return base32DecodeToData(self)
    }
    
    public var base32EncodedString: String {
        return nulTerminatedUTF8.withUnsafeBufferPointer {
            return base32encode($0.baseAddress, length: $0.count - 1, table: alphabetEncodeTable)
        }
    }
    
    public func base32DecodedString(encoding: NSStringEncoding = NSUTF8StringEncoding) -> String? {
        if let data = self.base32DecodedData {
            return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
        } else {
            return nil
        }
    }

    // base32Hex
    public var base32HexDecodedData: NSData? {
        return base32HexDecodeToData(self)
    }
    
    public var base32HexEncodedString: String {
        return nulTerminatedUTF8.withUnsafeBufferPointer {
            return base32encode($0.baseAddress, length: $0.count - 1, table: extendedHexAlphabetEncodeTable)
        }
    }
    
    public func base32HexDecodedString(encoding: NSStringEncoding = NSUTF8StringEncoding) -> String? {
        if let data = self.base32HexDecodedData {
            return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
        } else {
            return nil
        }
    }
}

extension NSData {
    // base32
    public var base32EncodedString: String {
        return base32Encode(self)
    }
    
    public var base32EncodedData: NSData {
        return base32EncodedString.dataUsingUTF8StringEncoding
    }
    
    public var base32DecodedData: NSData? {
        if let string = NSString(data: self, encoding: NSUTF8StringEncoding) as? String {
            return base32DecodeToData(string)
        } else {
            return nil
        }
    }

    // base32Hex
    public var base32HexEncodedString: String {
        return base32HexEncode(self)
    }
    
    public var base32HexEncodedData: NSData {
        return base32HexEncodedString.dataUsingUTF8StringEncoding
    }
    
    public var base32HexDecodedData: NSData? {
        if let string = NSString(data: self, encoding: NSUTF8StringEncoding) as? String {
            return base32HexDecodeToData(string)
        } else {
            return nil
        }
    }
}

// MARK: - private

// MARK: encode

extension Int8: UnicodeScalarLiteralConvertible {
    public init(unicodeScalarLiteral value: UnicodeScalar) {
        self.init(value.value)
    }
}

let alphabetEncodeTable: [Int8] = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","2","3","4","5","6","7"]

let extendedHexAlphabetEncodeTable: [Int8] = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V"]

private func base32encode(data: UnsafePointer<Void>, var length: Int, table: [Int8]) -> String {
    if length == 0 {
        return ""
    }
    
    var bytes = UnsafePointer<UInt8>(data)
    
    let resultBufferSize = Int(ceil(Double(length) / 5)) * 8 + 1    // need null termination
    let resultBuffer = UnsafeMutablePointer<Int8>.alloc(resultBufferSize)
    var encoded = resultBuffer
    
    // encode regular blocks
    while length >= 5 {
        encoded[0] = table[Int(bytes[0] >> 3)]
        encoded[1] = table[Int((bytes[0] & 0b00000111) << 2 | bytes[1] >> 6)]
        encoded[2] = table[Int((bytes[1] & 0b00111110) >> 1)]
        encoded[3] = table[Int((bytes[1] & 0b00000001) << 4 | bytes[2] >> 4)]
        encoded[4] = table[Int((bytes[2] & 0b00001111) << 1 | bytes[3] >> 7)]
        encoded[5] = table[Int((bytes[3] & 0b01111100) >> 2)]
        encoded[6] = table[Int((bytes[3] & 0b00000011) << 3 | bytes[4] >> 5)]
        encoded[7] = table[Int((bytes[4] & 0b00011111))]
        length -= 5
        encoded = encoded.advancedBy(8)
        bytes = bytes.advancedBy(5)
    }
    
    // encode last block
    var byte0, byte1, byte2, byte3, byte4: UInt8
    (byte0, byte1, byte2, byte3, byte4) = (0,0,0,0,0)
    switch length {
    case 4:
        byte3 = bytes[3]
        encoded[6] = table[Int((byte3 & 0b00000011) << 3 | byte4 >> 5)]
        encoded[5] = table[Int((byte3 & 0b01111100) >> 2)]
        fallthrough
    case 3:
        byte2 = bytes[2]
        encoded[4] = table[Int((byte2 & 0b00001111) << 1 | byte3 >> 7)]
        fallthrough
    case 2:
        byte1 = bytes[1]
        encoded[3] = table[Int((byte1 & 0b00000001) << 4 | byte2 >> 4)]
        encoded[2] = table[Int((byte1 & 0b00111110) >> 1)]
        fallthrough
    case 1:
        byte0 = bytes[0]
        encoded[1] = table[Int((byte0 & 0b00000111) << 2 | byte1 >> 6)]
        encoded[0] = table[Int(byte0 >> 3)]
    default: break
    }
    
    // padding
    switch length {
    case 0:
        encoded[0] = 0
    case 1:
        encoded[2] = "="
        encoded[3] = "="
        fallthrough
    case 2:
        encoded[4] = "="
        fallthrough
    case 3:
        encoded[5] = "="
        encoded[6] = "="
        fallthrough
    case 4:
        encoded[7] = "="
        fallthrough
    default:
        encoded[8] = 0
        break
    }
    
    // return
    if let base32Encoded = String(UTF8String: resultBuffer) {
        resultBuffer.dealloc(resultBufferSize)
        return base32Encoded
    } else {
        resultBuffer.dealloc(resultBufferSize)
        fatalError("internal error")
    }
}

// MARK: decode

let __: UInt8 = 255
let alphabetDecodeTable: [UInt8] = [
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x00 - 0x0F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x10 - 0x1F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x20 - 0x2F
    __,__,26,27, 28,29,30,31, __,__,__,__, __,__,__,__,  // 0x30 - 0x3F
    __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,  // 0x40 - 0x4F
    15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,  // 0x50 - 0x5F
    __, 0, 1, 2,  3, 4, 5, 6,  7, 8, 9,10, 11,12,13,14,  // 0x60 - 0x6F
    15,16,17,18, 19,20,21,22, 23,24,25,__, __,__,__,__,  // 0x70 - 0x7F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x80 - 0x8F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x90 - 0x9F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xA0 - 0xAF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xB0 - 0xBF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xC0 - 0xCF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xD0 - 0xDF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xE0 - 0xEF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xF0 - 0xFF
]

let extendedHexAlphabetDecodeTable: [UInt8] = [
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x00 - 0x0F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x10 - 0x1F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x20 - 0x2F
     0, 1, 2, 3,  4, 5, 6, 7,  8, 9,__,__, __,__,__,__,  // 0x30 - 0x3F
    __,10,11,12, 13,14,15,16, 17,18,19,20, 21,22,23,24,  // 0x40 - 0x4F
    25,26,27,28, 29,30,31,__, __,__,__,__, __,__,__,__,  // 0x50 - 0x5F
    __,10,11,12, 13,14,15,16, 17,18,19,20, 21,22,23,24,  // 0x60 - 0x6F
    25,26,27,28, 29,30,31,__, __,__,__,__, __,__,__,__,  // 0x70 - 0x7F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x80 - 0x8F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0x90 - 0x9F
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xA0 - 0xAF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xB0 - 0xBF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xC0 - 0xCF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xD0 - 0xDF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xE0 - 0xEF
    __,__,__,__, __,__,__,__, __,__,__,__, __,__,__,__,  // 0xF0 - 0xFF
]


private func base32decode(string: String, table: [UInt8]) -> [UInt8]? {
    let length = string.unicodeScalars.count
    if length == 0 {
        return []
    }
    
    // search element index that condition is true.
    func index_of<C : CollectionType where C.Generator.Element : Equatable>(domain: C, condition: C.Generator.Element -> Bool) -> C.Index? {
        return domain.lazy.map(condition).indexOf(true)
    }
    
    // calc padding length
    func getLeastPaddingLength(string: String) -> Int {
        if string.hasSuffix("======") {
            return 6
        } else if string.hasSuffix("====") {
            return 4
        } else if string.hasSuffix("===") {
            return 3
        } else if string.hasSuffix("=") {
            return 1
        } else {
            return 0
        }
    }
    
    // validate string
    let leastPaddingLength = getLeastPaddingLength(string)
    if let index = index_of(string.unicodeScalars, condition: {$0.value > 0xff || table[Int($0.value)] > 31}) {
        // index points padding "=" or invalid character that table does not contain.
        let pos = string.unicodeScalars.startIndex.distanceTo(index)
        // if pos points padding "=", it's valid.
        if pos != length - leastPaddingLength {
            print("string contains some invalid characters.")
            return nil
        }
    }
    
    var remainEncodedLength = length - leastPaddingLength
    var additionalBytes = 0
    switch remainEncodedLength % 8 {
        // valid
    case 0: break
    case 2: additionalBytes = 1
    case 4: additionalBytes = 2
    case 5: additionalBytes = 3
    case 7: additionalBytes = 4
    default:
        print("string length is invalid.")
        return nil
    }
    
    // validated
    let dataSize = remainEncodedLength / 8 * 5 + additionalBytes
    
    // Use UnsafePointer<UInt8>
    return string.nulTerminatedUTF8.withUnsafeBufferPointer {
        (data: UnsafeBufferPointer<UInt8>) -> [UInt8] in
        var encoded = data.baseAddress
        
        let result = Array<UInt8>(count: dataSize, repeatedValue: 0)
        var decoded = UnsafeMutablePointer<UInt8>(result)
        
        // decode regular blocks
        var value0, value1, value2, value3, value4, value5, value6, value7: UInt8
        (value0, value1, value2, value3, value4, value5, value6, value7) = (0,0,0,0,0,0,0,0)
        while remainEncodedLength >= 8 {
            value0 = table[Int(encoded[0])]
            value1 = table[Int(encoded[1])]
            value2 = table[Int(encoded[2])]
            value3 = table[Int(encoded[3])]
            value4 = table[Int(encoded[4])]
            value5 = table[Int(encoded[5])]
            value6 = table[Int(encoded[6])]
            value7 = table[Int(encoded[7])]
            
            decoded[0] = value0 << 3 | value1 >> 2
            decoded[1] = value1 << 6 | value2 << 1 | value3 >> 4
            decoded[2] = value3 << 4 | value4 >> 1
            decoded[3] = value4 << 7 | value5 << 2 | value6 >> 3
            decoded[4] = value6 << 5 | value7
            
            remainEncodedLength -= 8
            decoded = decoded.advancedBy(5)
            encoded = encoded.advancedBy(8)
        }
        
        // decode last block
        (value0, value1, value2, value3, value4, value5, value6, value7) = (0,0,0,0,0,0,0,0)
        switch remainEncodedLength {
        case 7:
            value6 = table[Int(encoded[6])]
            value5 = table[Int(encoded[5])]
            decoded[4] = value6 << 5 | value7
            fallthrough
        case 5:
            value4 = table[Int(encoded[4])]
            decoded[3] = value4 << 7 | value5 << 2 | value6 >> 3
            fallthrough
        case 4:
            value3 = table[Int(encoded[3])]
            value2 = table[Int(encoded[2])]
            decoded[2] = value3 << 4 | value4 >> 1
            fallthrough
        case 2:
            value1 = table[Int(encoded[1])]
            value0 = table[Int(encoded[0])]
            decoded[1] = value1 << 6 | value2 << 1 | value3 >> 4
            decoded[0] = value0 << 3 | value1 >> 2
        default: break
        }
        
        return result
    }
}

