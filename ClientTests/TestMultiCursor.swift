import Foundation
import XCTest

class TestMultiCursor : AccountTest {
    func testMultiCursor() {
        var a = [Int]()
        var b = [Int]()
        var c = [Int]()
        for i in 0..<5 {
            a.append(1)
            b.append(2)
            c.append(3)
        }

        var multi = MultiCursor()
        multi.addCursor(ArrayCursor(data: a))
        XCTAssertEqual(multi.count, 5, "Cursor has right count")
        XCTAssertEqual(multi[0] as Int, 1, "Cursor has right value")

        multi.addCursor(ArrayCursor(data: b))
        XCTAssertEqual(multi.count, 10, "Cursor has right count")
        XCTAssertEqual(multi[0] as Int, 1, "Cursor has right value")
        XCTAssertEqual(multi[6] as Int, 2, "Cursor has right value")

        multi.addCursor(ArrayCursor(data: c), index: 0)
        XCTAssertEqual(multi.count, 15, "Cursor has right count")
        XCTAssertEqual(multi[0] as Int, 3, "Cursor has right value")
        XCTAssertEqual(multi[6] as Int, 1, "Cursor has right value")
        XCTAssertEqual(multi[11] as Int, 2, "Cursor has right value")

        multi.removeAll()
        XCTAssertEqual(multi.count, 15, "Cursor has right count")

        /* This was supposed to check the use a multicursor where rows from different cursors were interspesed.
         * Getting that working introduces more complexity than we need in MultiCursor though, so I've left
         * it for later. */
        /*
        multi.addCursor(OddCursor(mod: 1, num: 2))
        multi.addCursor(OddCursor(mod: 0, num: 1))
        XCTAssertEqual(multi.count, 10, "Cursor has right count")
        for i in 0...9 {
            println("Multi \(multi[i])")
            if i % 2 == 0 {
                // XCTAssertEqual(multi[i] as Int, 1, "Even entries have right value")
            } else {
                // XCTAssertEqual(multi[i] as Int, 2, "Odd entries have right value")
            }
        }
        */
    }

    private class OddCursor: Cursor {
        let num: Int
        let mod: Int
        init(mod: Int, num: Int) {
            self.mod = mod
            self.num = num
            super.init(status: .Success, msg: "success")
        }

        override var count :Int { return 5 }

        override subscript(index: Int) -> Any? {
            println("Comparing \(index % 2) == \(mod)")
            if index % 2 == mod {
                return num
            }
            return nil
        }
    }
}