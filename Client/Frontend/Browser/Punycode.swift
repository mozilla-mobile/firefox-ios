/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

private let base = 36
private let tMin = 1
private let tMax = 26
private let initialBias = 72
private let initialN: Int = 128 // 0x80
private let delimiter: Character = "-"; // '\x2D'
private let prefixPunycode = "xn--"
private let asciiPunycode = [Character]("abcdefghijklmnopqrstuvwxyz0123456789".characters)

extension String {
    fileprivate func toValue(_ index: Int) -> Character {
        return asciiPunycode[index]
    }

    fileprivate func toIndex(_ value: Character) -> Int {
        return asciiPunycode.index(of: value)!
    }

    fileprivate func adapt(_ delta: Int, numPoints: Int, firstTime: Bool) -> Int {
        let skew = 38
        let damp = firstTime ? 700 : 2
        var delta = delta
        delta = delta / damp
        delta += delta / numPoints
        var k = 0
        while delta > ((base - tMin) * tMax) / 2 {
            delta /= (base - tMin)
            k += base
        }
        return k + ((base - tMin + 1) * delta) / (delta + skew)
    }

    fileprivate func encode(_ input: String) -> String {
        var output = ""
        var d: Int = 0
        var extendedChars = [Int]()
        for c in input.unicodeScalars {
            if Int(c.value) < initialN {
                d += 1
                output.append(String(c))
            } else {
                extendedChars.append(Int(c.value))
            }
        }
        if extendedChars.count == 0 {
            return output
        }
        if d > 0 {
            output.append(delimiter)
        }

        var n = initialN
        var delta = 0
        var bias = initialBias
        var h: Int = 0
        var b: Int = 0

        if d > 0 {
            h = output.unicodeScalars.count - 1
            b = output.unicodeScalars.count - 1
        } else {
            h = output.unicodeScalars.count
            b = output.unicodeScalars.count
        }

        while h < input.unicodeScalars.count {
            var char = Int(0x7fffffff)
            for c in input.unicodeScalars {
                let ci = Int(c.value)
                if char > ci && ci >= n {
                    char = ci
                }
            }
            delta = delta + (char - n) * (h + 1)
            if delta < 0 {
                print("error: invalid char:")
                output = ""
                return output
            }
            n = char
            for c in input.unicodeScalars {
                let ci = Int(c.value)
                if ci < n || ci < initialN {
                    delta += 1
                    continue
                }
                if ci > n {
                    continue
                }
                var q = delta
                var k = base
                while true {
                    let t = max(min(k - bias, tMax), tMin)
                    if q < t {
                        break
                    }
                    let code = t + ((q - t) % (base - t))
                    output.append(toValue(code))
                    q = (q - t) / (base - t)
                    k += base
                }
                output.append(toValue(q))
                bias = self.adapt(delta, numPoints: h + 1, firstTime: h == b)
                delta = 0
                h += 1
            }
            delta += 1
            n += 1
        }
        return output
    }

    fileprivate func decode(_ punycode: String) -> String {
        var input = [Character](punycode.characters)
        var output = [Character]()
        var i = 0
        var n = initialN
        var bias = initialBias
        var pos = 0
        if let ipos = input.index(of: delimiter) {
            pos = ipos
            output.append(contentsOf: input[0 ..< pos])
            pos += 1
        }
        var outputLength = output.count
        let inputLength = input.count
        while pos < inputLength {
            let oldi = i
            var w = 1
            var k = base
            while true {
                let digit = toIndex(input[pos])
                pos += 1
                i += digit * w
                let t = max(min(k - bias, tMax), tMin)
                if digit < t {
                    break
                }
                w = w * (base - t)
                k += base
            }
            outputLength += 1
            bias = adapt(i - oldi, numPoints: outputLength, firstTime: (oldi == 0))
            n = n + i / outputLength
            i = i % outputLength
            output.insert(Character(UnicodeScalar(n)!), at: i)
            i += 1
        }
        return String(output)
    }

    fileprivate func isValidUnicodeScala(_ s: String) -> Bool {
        for c in s.unicodeScalars {
            let ci = Int(c.value)
            if ci >= initialN {
                return false
            }
        }
        return true
    }

    fileprivate func isValidPunycodeScala(_ s: String) -> Bool {
        return s.hasPrefix(prefixPunycode)
    }

    public func utf8HostToAscii() -> String {
        if isValidUnicodeScala(self) {
            return self
        }
        var labels = self.components(separatedBy: ".")
        for (i, part) in labels.enumerated() {
            if !isValidUnicodeScala(part) {
                let a = encode(part)
                labels[i] = prefixPunycode + a
            }
        }
        let resultString = labels.joined(separator: ".")
        return resultString
    }

    public func asciiHostToUTF8() -> String {
        var labels = self.components(separatedBy: ".")
        for (index, part) in labels.enumerated() {
            if isValidPunycodeScala(part) {
                let changeStr = part.substring(from: part.characters.index(part.startIndex, offsetBy: 4))
                labels[index] = decode(changeStr)
            }
        }
        let resultString = labels.joined(separator: ".")
        return resultString
    }
}
