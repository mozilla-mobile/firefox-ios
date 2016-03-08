//
//  Base16.swift
//  Base32
//
//  Created by 野村 憲男 on 2/7/15.
//  Copyright (c) 2015 Norio Nomura. All rights reserved.
//

import Foundation

// MARK: - Base16 NSData <-> String

public func base16Encode(data: NSData, uppercase: Bool = true) -> String {
    return base16encode(data.bytes, length: data.length, uppercase: uppercase)
}

public func base16DecodeToData(string: String) -> NSData? {
    if let array = base16decode(string) {
        return NSData(bytes: array, length: array.count)
    } else {
        return nil
    }
}

// MARK: - Base16 [UInt8] <-> String

public func base16Encode(array: [UInt8], uppercase: Bool = true) -> String {
    return base16encode(array, length: array.count, uppercase: uppercase)
}

public func base16Decode(string: String) -> [UInt8]? {
    return base16decode(string)
}

// MARK: extensions

extension String {
    // base16
    public var base16DecodedData: NSData? {
        return base16DecodeToData(self)
    }
    
    public var base16EncodedString: String {
        return nulTerminatedUTF8.withUnsafeBufferPointer {
            return base16encode($0.baseAddress, length: $0.count - 1)
        }
    }
    
    public func base16DecodedString(encoding: NSStringEncoding = NSUTF8StringEncoding) -> String? {
        if let data = self.base16DecodedData {
            return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
        } else {
            return nil
        }
    }
}

extension NSData {
    // base16
    public var base16EncodedString: String {
        return base16Encode(self)
    }
    
    public var base16EncodedData: NSData {
        return base16EncodedString.dataUsingUTF8StringEncoding
    }
    
    public var base16DecodedData: NSData? {
        if let string = NSString(data: self, encoding: NSUTF8StringEncoding) as? String {
            return base16DecodeToData(string)
        } else {
            return nil
        }
    }
}

// MARK: encode
private func base16encode(data: UnsafePointer<Void>, length: Int, uppercase: Bool = true) -> String {
    let array = UnsafeBufferPointer<UInt8>(start: UnsafePointer<UInt8>(data), count: length)
    return array.map { String(format: uppercase ? "%02X" : "%02x", $0) }.reduce("", combine: +)
}

// MARK: decode
extension UnicodeScalar {
    private var hexToUInt8: UInt8? {
        switch self {
        case "0"..."9": return UInt8(value - UnicodeScalar("0").value)
        case "a"..."f": return UInt8(value - UnicodeScalar("a").value + 0xa)
        case "A"..."F": return UInt8(value - UnicodeScalar("A").value + 0xa)
        default:
            print("base16decode: Invalid hex character \(self)")
            return nil
        }
    }
}

private func base16decode(string: String) -> [UInt8]? {
    // validate length
    let lenght = string.nulTerminatedUTF8.count - 1
    if lenght % 2 != 0 {
        print("base16decode: String must contain even number of characters")
        return nil
    }
    var g = string.unicodeScalars.generate()
    var buffer = Array<UInt8>(count: lenght / 2, repeatedValue: 0)
    var index = 0
    while let msn = g.next() {
        if let msn = msn.hexToUInt8 {
            if let lsn = g.next()?.hexToUInt8 {
                buffer[index] = msn << 4 | lsn
            } else {
                return nil
            }
        } else {
            return nil
        }
        index++
    }
    return buffer
}
