import Quick
import Nimble
import UIKit
import Shared
import Storage

class TopSitesPanelTests: QuickSpec {
    override func spec() {
        describe("edit mode") {
            it("should clear button animation state when disabled") {
                fail()
            }

            it("tells the homePanelDelegate we're about to edit when enabled") {
                fail()
            }

            it("invalidates the collection view layout if we change it's value") {
                fail()
            }

            it("does not invalidate the layout if set to the same value as before") {
                fail()
            }
        }

        describe("tapping the remove tile button") {
            it("deletes the selected url from the history") {
                fail()
            }

            it("requeries the history database for fresh data") {
                fail()
            }

            it("deletes the associated cell from the collection view if we have more than thumbnailCount") {
                fail()
            }

            it("reloads all the data if we have less or equal to the thumbnailCount") {
                fail()
            }
        }
    }
}

class TopSitesCollectionViewDelegateTests: QuickSpec {
    override func spec() {
        describe("a close supplementary view") {
            it("is animated whenever it will be displayed") {
                fail()
            }

            it("is not animated if it's already appeared") {
                fail()
            }
        }
    }
}

class TopSitesLayoutTests: QuickSpec {
    override func spec() {
        describe("close button decorator view") {
            it("should be positioned to to the top left corner of the tile's image view") {
                fail()
            }

            it("should only exist for thumbnailTiles") {
                fail()
            }
        }
    }
}
