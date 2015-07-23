/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared

let BookmarkStatusChangedNotification = "BookmarkStatusChangedNotification"

class BookmarksPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var source: BookmarksModel?

    private lazy var defaultIcon: UIImage = {
        return UIImage(named: "defaultFavicon")!
    }()

    lazy var suggestedSites: SuggestedSitesData<Tile> = {
        return SuggestedSitesData<Tile>()
    }()

    override var profile: Profile! {
        didSet {
            // Until we have something useful to show for desktop bookmarks,
            // only show mobile bookmarks.
            // Note that we also need to build a similar kind of virtual hierarchy
            // to what we have on Android.
            profile.bookmarks.modelForFolder(BookmarkRoots.MobileFolderGUID, success: self.onNewModel, failure: self.onModelFailure)
            // profile.bookmarks.modelForRoot(self.onNewModel, failure: self.onModelFailure)
        }
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "firefoxAccountChanged:", name: NotificationFirefoxAccountChanged, object: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationFirefoxAccountChanged, object: nil)
    }

    func firefoxAccountChanged(notification: NSNotification) {
        if notification.name == NotificationFirefoxAccountChanged {
            self.reloadData()
        }
    }

    private func onNewModel(model: BookmarksModel) {
        if model.current.count == 0 && model.current.guid == BookmarkRoots.MobileFolderGUID {
            self.source = nil
        } else {
            self.source = model
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    private func onModelFailure(e: Any) {
        println("Error: failed to get data: \(e)")
    }

    override func reloadData() {
        self.source?.reloadData(self.onNewModel, failure: self.onModelFailure)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let source = source {
            return source.current.count
        }
        return suggestedSites.count
    }

    private func setupSuggestedSiteForCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let tile = suggestedSites[indexPath.row]
        cell.textLabel?.text = tile?.title
        cell.imageView?.setIcon(tile?.icon, withPlaceholder: self.defaultIcon)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let source = source {
            if let bookmark = source.current[indexPath.row] {
                if let favicon = bookmark.favicon {
                    cell.imageView?.setIcon(favicon, withPlaceholder: self.defaultIcon)
                }

                switch (bookmark) {
                    case let item as BookmarkItem:
                        if item.title.isEmpty {
                            cell.textLabel?.text = item.url
                        } else {
                            cell.textLabel?.text = item.title
                        }
                    default:
                        // Bookmark folders don't have a good fallback if there's no title. :(
                        cell.textLabel?.text = bookmark.title
                }
            }
        } else {
            // If we don't have a source at all, show suggested sites
            setupSuggestedSiteForCell(cell, indexPath: indexPath)
        }

        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        // Don't show a header for the root
        if source?.current.guid == BookmarkRoots.MobileFolderGUID {
            return nil
        }

        // Note: If there's no root (i.e. source == nil), we'll also show no header.
        return source?.current.title
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Don't show a header for the root. If there's no root (i.e. source == nil), we'll also show no header.
        if source == nil || source?.current.guid == BookmarkRoots.MobileFolderGUID {
            return 0
        }

        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        if let source = source {
            let bookmark = source.current[indexPath.row]

            switch (bookmark) {
            case let item as BookmarkItem:
                homePanelDelegate?.homePanel(self, didSelectURL: NSURL(string: item.url)!, visitType: VisitType.Bookmark)
                break

            case let folder as BookmarkFolder:
                // Descend into the folder.
                source.selectFolder(folder, success: self.onNewModel, failure: self.onModelFailure)
                break

            default:
                // Weird.
                break        // Just here until there's another executable statement (compiler requires one).
            }
        } else {
            if let tile = suggestedSites[indexPath.row] {
                homePanelDelegate?.homePanel(self, didSelectURL: NSURL(string: tile.url)!, visitType: VisitType.Bookmark)
            }
        }
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }

    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let title = NSLocalizedString("Delete", tableName: "BookmarkPanel", comment: "Action button for deleting bookmarks in the bookmarks panel.")

        let delete = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: title, handler: { (action, indexPath) in

            if let bookmark = self.source?.current[indexPath.row] {
                // Why the dispatches? Because we call success and failure on the DB
                // queue, and so calling anything else that calls through to the DB will
                // deadlock. This problem will go away when the bookmarks API switches to
                // Deferred instead of using callbacks.
                self.profile.bookmarks.remove(bookmark).uponQueue(dispatch_get_main_queue()) { res in
                    if let err = res.failureValue {
                        self.onModelFailure(err)
                        return
                    }

                    dispatch_async(dispatch_get_main_queue()) {
                        self.source?.reloadData({ model in
                            dispatch_async(dispatch_get_main_queue()) {
                                tableView.beginUpdates()
                                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Left)

                                if model.current.count == 0 && model.current.guid == BookmarkRoots.MobileFolderGUID {
                                    // If the new model is the root, and its empty, set the source to nil so that we
                                    // correctly show suggested sites.
                                    self.source = nil
                                    var indexPaths = [NSIndexPath]()
                                    for i in 0..<self.suggestedSites.count {
                                        let indexPath = NSIndexPath(forItem: i, inSection: 0)
                                        indexPaths.append(indexPath)
                                    }
                                    self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Right)
                                } else {
                                    self.source = model
                                }

                                tableView.endUpdates()

                                NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: bookmark, userInfo:["added":false])
                            }
                        }, failure: self.onModelFailure)
                    }
                }
            }
        })

        return [delete]
    }
}
