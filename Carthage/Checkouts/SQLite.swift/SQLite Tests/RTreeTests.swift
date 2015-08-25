import XCTest
import SQLite

let minX = Expression<Double>("minX")
let maxX = Expression<Double>("maxX")
let minY = Expression<Double>("minY")
let maxY = Expression<Double>("maxY")

class RTreeTests: SQLiteTestCase {

    var index: Query { return db["index"] }

    func test_createVtable_usingRtree_createsVirtualTable() {
        db.create(vtable: index, using: rtree(id, minX, maxX, minY, maxY))

        AssertSQL("CREATE VIRTUAL TABLE \"index\" USING rtree(\"id\", \"minX\", \"maxX\", \"minY\", \"maxY\")")
    }

}
