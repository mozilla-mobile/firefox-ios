import Quick
import Nimble
import UIKit
import Shared
import Storage
import Client

@objc class MockHomePanelDelegate: NSObject, HomePanelDelegate {
    var didSelectURL = false
    var didEnterEditingMode = false

    func homePanel(homePanel: HomePanel, didSelectURL url: NSURL, visitType: VisitType) {
        didSelectURL = true
    }

    func homePanelWillEnterEditingMode(homePanel: HomePanel) {
        didEnterEditingMode = true
    }
}

@objc class MockTopSitesCollectionViewDelegate: NSObject, TopSitesCollectionViewDelegate {
    var dataSource: TopSitesDataSource?
    var homePanelDelegate: HomePanelDelegate?
    var homePanel: HomePanel?
    var closeButtonDidAnimateMap = [Int: Bool]()
}


class MockLayout: TopSitesLayout {
    var didInvalidateLayout = false

    override func invalidateLayout() {
        didInvalidateLayout = true
    }
}

private func addSite(history: BrowserHistory, url: String, title: String, callback: (success: Bool) -> Void) {
    // Add an entry
    let site = Site(url: url, title: title)
    let visit = SiteVisit(site: site, date: NSDate.nowMicroseconds())
    history.addLocalVisit(visit).upon {
        callback(success: $0.isSuccess)
    }
}

class TopSitesPanelTests: QuickSpec {
    override func spec() {
        var panel: TopSitesPanel!
        var mockHomePanelDelegate: MockHomePanelDelegate!
        var mockLayout: MockLayout!
        var mockProfile: MockProfile!

        beforeEach {
            panel = TopSitesPanel()
            mockHomePanelDelegate = MockHomePanelDelegate()
            mockLayout = MockLayout()
            mockProfile = MockProfile()

            panel.delegate = MockTopSitesCollectionViewDelegate()
            panel.homePanelDelegate = mockHomePanelDelegate
            panel.layout = mockLayout
//            panel.profile = mockProfile
        }

        describe("edit mode") {
            it("should clear button animation state when disabled") {
                panel.editMode = true
                panel.delegate.closeButtonDidAnimateMap[0] = true
                expect(panel.delegate.closeButtonDidAnimateMap.count).to(equal(1))
                panel.editMode = false
                expect(panel.delegate.closeButtonDidAnimateMap.count).to(equal(0))
            }

            it("tells the homePanelDelegate we're about to edit when enabled") {
                panel.editMode = true
                expect(mockHomePanelDelegate.didEnterEditingMode).to(beTrue())
            }

            it("invalidates the collection view layout if we change it's value") {
                panel.editMode = true
                expect(mockLayout.didInvalidateLayout).to(beTrue())
                mockLayout.didInvalidateLayout = false
                panel.editMode = false
                expect(mockLayout.didInvalidateLayout).to(beTrue())
            }

            it("does not invalidate the layout if set to the same value as before") {
                panel.editMode = false
                expect(mockLayout.didInvalidateLayout).to(beFalse())
            }
        }

        describe("tapping the remove tile button") {
            beforeEach {
                // Seed the history tables with some data for testing
            }

            it("deletes the selected url from the history") {
            }

            it("requeries the history database for fresh data") {
            }

            it("deletes the associated cell from the collection view if we have more than thumbnailCount") {
            }

            it("reloads all the data if we have less or equal to the thumbnailCount") {
            }

            afterEach {
                // Clear out any history we messed with
            }
        }
    }
}

class TopSitesCollectionViewDelegateTests: QuickSpec {
    override func spec() {
        describe("a close supplementary view") {
            it("is animated whenever it will be displayed") {
            }

            it("is not animated if it's already appeared") {
            }
        }
    }
}

class TopSitesLayoutTests: QuickSpec {
    override func spec() {
        describe("close button decorator view") {
            it("should be positioned to to the top left corner of the tile's image view") {
            }

            it("should only exist for thumbnail tiles") {
            }
        }
    }
}
