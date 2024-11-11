/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

fileprivate extension Int {
    static let base = 36
    static let tMin = 1
    static let tMax = 26
    static let initialBias = 72
    static let initialN: Int = 128 // 0x80
}

fileprivate extension Character {
    static let delimiter: Character = "-"
}

fileprivate extension String {
    static let prefixPunycode = "xn--"
    static let asciiPunycode = Array("abcdefghijklmnopqrstuvwxyz0123456789")
}

extension String {
    var isUrl: Bool {
        do {
            let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
            guard let match = detector.firstMatch(in: self, range: NSRange(location: 0, length: self.count)), match.range.length == self.count else {
                return false
            }

            return true
        } catch {
            assertionFailure("Couldn't find data detector for type link")
            return false
        }
    }

    fileprivate func toValue(_ index: Int) -> Character {
        return String.asciiPunycode[index]
    }

    fileprivate func toIndex(_ value: Character) -> Int {
        return String.asciiPunycode.firstIndex(of: value)!
    }

    fileprivate func adapt(_ delta: Int, numPoints: Int, firstTime: Bool) -> Int {
        let skew = 38
        let damp = firstTime ? 700 : 2
        var delta = delta
        delta = delta / damp
        delta += delta / numPoints
        var k = 0
        while delta > ((Int.base - Int.tMin) * Int.tMax) / 2 {
            delta /= (Int.base - Int.tMin)
            k += Int.base
        }
        return k + ((Int.base - Int.tMin + 1) * delta) / (delta + skew)
    }

    fileprivate func encode(_ input: String) -> String {
        var output = ""
        var d: Int = 0
        var extendedChars = [Int]()
        for c in input.unicodeScalars {
            if Int(c.value) < Int.initialN {
                d += 1
                output.append(String(c))
            } else {
                extendedChars.append(Int(c.value))
            }
        }
        if extendedChars.isEmpty {
            return output
        }
        if d > 0 {
            output.append(Character.delimiter)
        }

        var n = Int.initialN
        var delta = 0
        var bias = Int.initialBias
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
                if ci < n || ci < Int.initialN {
                    delta += 1
                    continue
                }
                if ci > n {
                    continue
                }
                var q = delta
                var k = Int.base
                while true {
                    let t = max(min(k - bias, Int.tMax), Int.tMin)
                    if q < t {
                        break
                    }
                    let code = t + ((q - t) % (Int.base - t))
                    output.append(toValue(code))
                    q = (q - t) / (Int.base - t)
                    k += Int.base
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
        let input = Array(punycode)
        var output = [Character]()
        var i = 0
        var n = Int.initialN
        var bias = Int.initialBias
        var pos = 0
        if let ipos = input.lastIndex(of: Character.delimiter) {
            pos = ipos
            output.append(contentsOf: input[0 ..< pos])
            pos += 1
        }
        var outputLength = output.count
        let inputLength = input.count
        while pos < inputLength {
            let oldi = i
            var w = 1
            var k = Int.base
            while true {
                let digit = toIndex(input[pos])
                pos += 1
                i += digit * w
                let t = max(min(k - bias, Int.tMax), Int.tMin)
                if digit < t {
                    break
                }
                w = w * (Int.base - t)
                k += Int.base
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
            if ci >= Int.initialN {
                return false
            }
        }
        return true
    }

    fileprivate func isValidPunycodeScala(_ s: String) -> Bool {
        return s.hasPrefix(String.prefixPunycode)
    }

    public func utf8HostToAscii() -> String {
        if isValidUnicodeScala(self) {
            return self
        }
        var labels = self.components(separatedBy: ".")
        for (index, part) in labels.enumerated() where !isValidUnicodeScala(part) {
            let a = encode(part)
            labels[index] = String.prefixPunycode + a
        }
        let resultString = labels.joined(separator: ".")
        return resultString
    }

    public func asciiHostToUTF8() -> String {
        var labels = self.components(separatedBy: ".")
        for (index, part) in labels.enumerated() where isValidPunycodeScala(part) {
            let changeStr = String(part[part.index(part.startIndex, offsetBy: 4)...])
            labels[index] = decode(changeStr)
        }
        let resultString = labels.joined(separator: ".")
        return resultString
    }
}
