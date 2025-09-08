// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCTest

class ArrayExtensionTests: XCTestCase {
    func testUnique() {
        let a = [1, 2, 3, 4, 5, 6, 1, 2]
        let result = a.unique { return $0 }
        XCTAssertEqual(result, [1, 2, 3, 4, 5, 6])

        let b = [1, 2, 3]
        let resultB = b.unique { return $0 }
        XCTAssertEqual(resultB, [1, 2, 3])
    }

    func testUniqued() {
        let a = [1, 2, 3, 4, 5, 6, 1, 2]
        let result = a.uniqued()
        XCTAssertEqual(result, [1, 2, 3, 4, 5, 6])

        let b = [1, 2, 3]
        let resultB = b.uniqued()
        XCTAssertEqual(resultB, [1, 2, 3])

        let c = [1, 1, 1, 1, 1]
        let resultC = c.uniqued()
        XCTAssertEqual(resultC, [1])
    }

    func testDuplicates() {
        let a = [1, 2, 3, 4, 5, 6, 1, 2]
        let result = a.duplicates()
        XCTAssertEqual(result, [1, 2])

        let b = [1, 2, 3]
        let resultB = b.duplicates()
        XCTAssertEqual(resultB, [])

        let c = [1, 1, 1, 1]
        let resultC = c.duplicates()
        XCTAssertEqual(resultC, [1, 1, 1])
    }

    func testUnion() {
        let a = [1, 2, 3, 4, 5, 6]
        let b = [7, 8, 9, 10]
        XCTAssertEqual(a.union(b) { return $0 },
                       [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

        let c = [1, 2, 3, 4, 5, 6]
        let d = [4, 5, 6, 7, 8, 9, 10]
        XCTAssertEqual(c.union(d) { return $0 }, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

        let e = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let f = [4, 5, 6, 7, 8, 9, 10]
        XCTAssertEqual(e.union(f) { return $0 }, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

        let g = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        let h = [Int]()
        XCTAssertEqual(g.union(h) { return $0 }, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])

        let i = [Int]()
        let j = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        XCTAssertEqual(i.union(j) { return $0 }, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
    }

    func testSameElements() {
        let k = [1, 2, 3, 4, 5]
        let l = [1, 2, 3, 4, 5]
        let m = [2, 4, 6, 8, 10]
        let n: [Int]?
        n = k
        XCTAssertTrue(k.sameElements(l))
        XCTAssertFalse(l.sameElements(m))
        XCTAssertTrue((n?.sameElements(k))!)
    }

    // MARK: - Testing the `.joined` extension
    func testJoiningNSAttributedStringArray_returnExpectedResult() {
        let blueFont = [NSAttributedString.Key.foregroundColor: UIColor.blue]
        let backgroundColour = [NSAttributedString.Key.backgroundColor: UIColor.yellow]
        let boldFont = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 13)]
        let italicizedFont = [NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 13)]

        let i = NSAttributedString(string: "Just ", attributes: blueFont)
        let j = NSAttributedString(string: "a small ", attributes: backgroundColour)
        let k = NSAttributedString(string: "town ", attributes: boldFont)
        let l = NSAttributedString(string: "girl!", attributes: italicizedFont)
        let array = [i, j, k, l]

        let expectedResult = NSMutableAttributedString()
        expectedResult.append(i)
        expectedResult.append(j)
        expectedResult.append(k)
        expectedResult.append(l)

        let result = array.joined()

        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(result.attributes(at: 0, effectiveRange: nil) as? [NSAttributedString.Key: UIColor],
                       blueFont)
        XCTAssertEqual(result.attributes(at: 5, effectiveRange: nil) as? [NSAttributedString.Key: UIColor],
                       backgroundColour)
        XCTAssertEqual(result.attributes(at: 13, effectiveRange: nil) as? [NSAttributedString.Key: UIFont],
                       boldFont)
        XCTAssertEqual(result.attributes(at: 18, effectiveRange: nil) as? [NSAttributedString.Key: UIFont],
                       italicizedFont)
    }
}
