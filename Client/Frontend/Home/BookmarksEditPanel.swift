/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage
import Shared
import XCGLogger

private let log = Logger.browserLogger

enum DetailPanel: Int {
    case Title = 0
    case URL
    case Folder
    case _numberOfPanels
}

struct BookmarksEditPanelUX {
    private static let LabelLeftRightPadding = 20
    private static let LabelTopBottomPadding = 10
    private static let TextFieldTopBottomPadding = 5
}

class BookmarksEditPanel: SiteTableViewController, HomePanel, UITextFieldDelegate {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var source: BookmarksModel?
    var parentFolders = [BookmarkFolder]()
    var bookmarkFolder: BookmarkFolder?
    var bookmark: BookmarkItem?
    
    var titleField: UITextField?
    var urlField: UITextField?
    var doneButton: UIButton?
    
    lazy var deleteButtonCell = ButtonPanelCell(style: UITableViewCellStyle.Default, reuseIdentifier: "ButtonPanelCell")
    var deleteButton: UIButton!
    
    private let BookmarksEditPanelCellIdentifier = "BookmarksEditPanelCellIdentifier"
    private let BookmarkFolderEditHeaderViewIdentifier = "BookmarkFolderEditHeaderIdentifier"
    
    init() {
        super.init(nibName: nil, bundle: nil)
        
        deleteButton = deleteButtonCell.button
        deleteButton.setTitle(deleteDeleteButtonLabel, forState: UIControlState.Normal)
        deleteButton.setTitleColor(UIColor.redColor(), forState: UIControlState.Normal)
        deleteButton.setTitleColor(UIColor.redColor().colorWithAlphaComponent(0.5), forState: UIControlState.Highlighted)
        deleteButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        deleteButton.addTarget(self, action: #selector(BookmarksEditPanel.deletePressed), forControlEvents: .TouchUpInside)
        
        self.tableView.registerClass(BookmarkFolderEditTableViewHeader.self, forHeaderFooterViewReuseIdentifier: BookmarkFolderEditHeaderViewIdentifier)
        self.tableView.registerClass(BookmarksEditPanelCell.self, forCellReuseIdentifier: BookmarksEditPanelCellIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.accessibilityIdentifier = "Bookmarks List"
        self.tableView.backgroundColor = UIColor(red: 240/255, green: 240/255, blue: 240/255, alpha: 1)
    }
    
    func deletePressed() {
        guard let source = self.source,
              let bookmark = self.bookmark else {
                return
        }
        
        guard let factory = source.modelFactory.value.successValue else {
            log.error("Couldn't get model factory. This is unexpected.")
            self.onModelFailure(DatabaseError(description: "Unable to get factory."))
            return
        }
        
        if let err = factory.removeByGUID(bookmark.guid).value.failureValue {
            log.debug("Failed to remove \(bookmark.guid).")
            self.onModelFailure(err)
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: bookmark, userInfo:["added": false])
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    private func onModelFailure(e: Any) {
        log.error("Error: failed to get data: \(e)")
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return DetailPanel._numberOfPanels.rawValue
        case 1:
            return 1
        default:
            return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCellWithIdentifier(BookmarksEditPanelCellIdentifier, forIndexPath: indexPath) as! BookmarksEditPanelCell
            switch DetailPanel(rawValue: indexPath.row) ?? .Title {
            case .Title:
                cell.label.text = NSLocalizedString("Title", comment: "The title of a bookmark.")
                cell.textField.text = bookmark?.title
                if titleField == nil {
                    titleField = cell.textField
                    cell.textField.addTarget(self, action: #selector(BookmarksEditPanel.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
                    cell.textField.delegate = self
                }
            case .URL:
                cell.label.text = NSLocalizedString("URL", comment: "URL of a bookmark.")
                cell.textField.text = bookmark?.url
                if urlField == nil {
                    urlField = cell.textField
                    cell.textField.addTarget(self, action: #selector(BookmarksEditPanel.textFieldDidChange(_:)), forControlEvents: UIControlEvents.EditingChanged)
                    cell.textField.delegate = self
                }
            case .Folder:
                cell.label.text = NSLocalizedString("Folder", comment: "Folder name of a bookmark.")
                cell.textField.text = bookmarkFolder?.title ?? NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
                cell.textField.enabled = false
            default:
                break
            }
            return cell
            
        case 1:
            return deleteButtonCell
            
        default:
            // This should never happen.
            return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        }
    }
    
    func textFieldDidChange(textField: UITextField) {
        doneButton?.enabled = true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func doneAndSave(button: UIButton) {
        guard let source = self.source,
              let bookmark = self.bookmark else {
            return
        }
        
        guard let factory = source.modelFactory.value.successValue else {
            log.error("Couldn't get model factory. This is unexpected.")
            self.onModelFailure(DatabaseError(description: "Unable to get factory."))
            return
        }
        
        if let err = factory.updateByGUID(BookmarkItem(guid: bookmark.guid, title: titleField?.text ?? bookmark.title, url: urlField?.text ?? bookmark.url)).value.failureValue {
            log.debug("Failed to remove \(bookmark.guid).")
            self.onModelFailure(err)
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(BookmarkStatusChangedNotification, object: bookmark, userInfo:["added": false])
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section != 0 {
            return nil
        }
        
        // Don't show a header for the root
        if source == nil || parentFolders.isEmpty {
            return nil
        }
        guard let header = tableView.dequeueReusableHeaderFooterViewWithIdentifier(BookmarkFolderEditHeaderViewIdentifier) as? BookmarkFolderEditTableViewHeader else { return nil }
        
        doneButton = header.doneButton
        
        header.doneButton.removeTarget(self, action: #selector(BookmarksEditPanel.doneAndSave(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        header.doneButton.addTarget(self, action: #selector(BookmarksEditPanel.doneAndSave(_:)), forControlEvents: UIControlEvents.TouchUpInside)
        
        // register as delegate to ensure we get notified when the user interacts with this header
        if header.delegate == nil {
            header.delegate = self
        }
        
        if parentFolders.count == 1 {
            header.textLabel?.text = NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
        } else if let parentFolder = parentFolders.last {
            header.textLabel?.text = parentFolder.title
        }
        header.contentView.backgroundColor = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
        
        return header
    }
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.row == 2 {
            return indexPath
        }
        return nil
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.row == 2;
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        
    }
    
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Don't show a header for the root. If there's no root (i.e. source == nil), we'll also show no header.
        if source == nil || parentFolders.isEmpty {
            return 0
        }
        
        return SiteTableViewControllerUX.RowHeight
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let header = view as? BookmarkFolderEditTableViewHeader {
            // for some reason specifying the font in header view init is being ignored, so setting it here
            header.textLabel?.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        }
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }
    
    override func tableView(tableView: UITableView, hasFullWidthSeparatorForRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Show a full-width border for cells above separators, so they don't have a weird step.
        // Separators themselves already have a full-width border, but let's force the issue
        // just in case.
        let this = self.source?.current[indexPath.row]
        if (indexPath.row + 1) < self.source?.current.count {
            let below = self.source?.current[indexPath.row + 1]
            if this is BookmarkSeparator || below is BookmarkSeparator {
                return true
            }
        }
        return super.tableView(tableView, hasFullWidthSeparatorForRowAtIndexPath: indexPath)
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Intentionally blank. Required to use UITableViewRowActions
    }
}

class BookmarksEditPanelCell: UITableViewCell {
    lazy var label = UILabel()
    lazy var textField = UITextField()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(label)
        addSubview(textField)
        
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallHistoryPanel
        textField.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        
        label.snp_makeConstraints { make in
            make.left.equalTo(self.snp_left).offset(BookmarksEditPanelUX.LabelLeftRightPadding)
            make.right.equalTo(self.snp_right).offset(-BookmarksEditPanelUX.LabelLeftRightPadding)
            make.top.equalTo(self.snp_top).offset(BookmarksEditPanelUX.LabelTopBottomPadding)
        }
        textField.snp_makeConstraints { make in
            make.top.equalTo(label.snp_bottom).offset(BookmarksEditPanelUX.TextFieldTopBottomPadding)
            make.left.equalTo(label.snp_left)
            make.right.equalTo(label.snp_right)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ButtonPanelCell: UITableViewCell {
    lazy var button = UIButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(button)
        button.snp_makeConstraints { make in
            make.right.left.top.bottom.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BookmarkFolderEditTableViewHeader: BookmarkFolderTableViewHeader {
    lazy var doneButton = UIButton()
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        doneButton.setTitle("Done", forState: UIControlState.Normal)
        doneButton.setTitleColor(doneButton.tintColor, forState: UIControlState.Normal)
        doneButton.setTitleColor(doneButton.tintColor.colorWithAlphaComponent(0.5), forState: UIControlState.Highlighted)
        doneButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        doneButton.enabled = false
        
        addSubview(doneButton)
        doneButton.snp_makeConstraints { make in
            make.bottom.equalTo(self.snp_bottom)
            make.right.equalTo(self.snp_right).offset(-BookmarksEditPanelUX.LabelLeftRightPadding)
            make.top.equalTo(self.snp_top)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension BookmarksEditPanel: BookmarkFolderTableViewHeaderDelegate {
    func didSelectHeader() {
        self.navigationController?.popViewControllerAnimated(true)
    }
}