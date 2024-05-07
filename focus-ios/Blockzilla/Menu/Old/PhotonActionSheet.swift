/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

// Ported with modifications from Firefox iOS (https://github.com/mozilla-mobile/firefox-ios)
public struct PhotonActionSheetItem {
    public enum IconAlignment {
        case left
        case right
    }

    public enum TextStyle {
        case normal
        case subtitle
    }

    public private(set) var title: String
    public private(set) var text: String?
    public private(set) var textStyle: TextStyle
    public private(set) var iconString: String?
    public private(set) var iconURL: URL?
    public private(set) var iconAlignment: IconAlignment

    public var isEnabled: Bool
    public private(set) var accessory: PhotonActionSheetCellAccessoryType
    public private(set) var accessoryText: String?
    public private(set) var bold = false
    public private(set) var handler: ((PhotonActionSheetItem) -> Void)?

    init(title: String, text: String? = nil, textStyle: TextStyle = .normal, iconString: String? = nil, iconAlignment: IconAlignment = .left, isEnabled: Bool = false, accessory: PhotonActionSheetCellAccessoryType = .None, accessoryText: String? = nil, bold: Bool? = false, handler: ((PhotonActionSheetItem) -> Void)? = nil) {
        self.title = title
        self.iconString = iconString
        self.iconAlignment = iconAlignment
        self.isEnabled = isEnabled
        self.accessory = accessory
        self.handler = handler
        self.text = text
        self.textStyle = textStyle
        self.accessoryText = accessoryText
        self.bold = bold ?? false
    }
}

protocol PhotonActionSheetDelegate: AnyObject {
    func photonActionSheetDidDismiss()
    func photonActionSheetDidToggleProtection(enabled: Bool)
}

class PhotonActionSheet: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    weak var delegate: PhotonActionSheetDelegate?
    private(set) var actions: [[PhotonActionSheetItem]]

    private let tintColor = UIColor.grey10
    private var tableView = UITableView(frame: .zero, style: .grouped)
    private let titleHeaderName = "PhotonActionSheetTitleHeaderView"

    lazy var tapRecognizer: UITapGestureRecognizer = {
        let tapRecognizer = UITapGestureRecognizer()
        tapRecognizer.addTarget(self, action: #selector(dismiss))
        tapRecognizer.numberOfTapsRequired = 1
        tapRecognizer.cancelsTouchesInView = false
        tapRecognizer.delegate = self
        return tapRecognizer
    }()

    var photonTransitionDelegate: UIViewControllerTransitioningDelegate? {
        didSet {
            self.transitioningDelegate = photonTransitionDelegate
        }
    }

    init(title: String? = nil, actions: [[PhotonActionSheetItem]]) {
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.backgroundColor = .clear
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(tableView)
        view.accessibilityIdentifier = "Action Sheet"
        view.isOpaque = false
        tableView.isOpaque = false

        let width = UIDevice.current.userInterfaceIdiom == .pad ? 400 : 250

        tableView.snp.makeConstraints { make in
            make.top.bottom.equalTo(self.view)
            make.width.equalTo(width)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .onDrag
        tableView.register(PhotonActionSheetCell.self, forCellReuseIdentifier: PhotonActionSheetCell.reuseIdentifier)
        tableView.register(PhotonActionSheetSeparator.self, forHeaderFooterViewReuseIdentifier: "SeparatorSectionHeader")
        tableView.register(PhotonActionSheetTitleHeaderView.self, forHeaderFooterViewReuseIdentifier: titleHeaderName)
        tableView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "EmptyHeader")
        tableView.estimatedRowHeight = UIConstants.layout.actionSheetRowHeight
        tableView.estimatedSectionFooterHeight = UIConstants.layout.actionSheetHeaderFooterHeight
        tableView.estimatedSectionHeaderHeight = UIConstants.layout.actionSheetHeaderFooterHeight
        tableView.isScrollEnabled = true
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = UIConstants.layout.actionSheetCornerRadius
        tableView.separatorStyle = .none
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.accessibilityIdentifier = "Context Menu"
        let origin = CGPoint(x: 0, y: 0)
        let size = CGSize(width: tableView.frame.width, height: UIConstants.layout.actionSheetPadding)
        let footer = UIView(frame: CGRect(origin: origin, size: size))
        tableView.tableHeaderView = footer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.preferredContentSize = self.tableView.contentSize
    }

    @objc
    func dismiss(_ gestureRecognizer: UIGestureRecognizer? = nil) {
        delegate?.photonActionSheetDidDismiss()
        self.dismiss(animated: true, completion: nil)
    }

    func dismissWithCallback(callback: @escaping () -> Void) {
        delegate?.photonActionSheetDidDismiss()
        self.dismiss(animated: true) { callback() }
    }

    @objc
    func didToggle(enabled: Bool) {
        delegate?.photonActionSheetDidToggleProtection(enabled: enabled)
        dismiss()
        delegate?.photonActionSheetDidDismiss()
    }

    deinit {
        tableView.dataSource = nil
        tableView.delegate = nil
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if self.traitCollection.verticalSizeClass != previousTraitCollection?.verticalSizeClass
            || self.traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            updateViewConstraints()
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if tableView.frame.contains(touch.location(in: self.view)) {
            return false
        }
        return true
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return actions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return actions[section].count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)
        var action = actions[indexPath.section][indexPath.row]
        guard let handler = action.handler else {
            self.dismiss()
            return
        }

        if action.accessory == .Switch {
            action.isEnabled = !action.isEnabled
            actions[indexPath.section][indexPath.row] = action
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView.reloadData()
            delegate?.photonActionSheetDidToggleProtection(enabled: action.isEnabled)
            handler(action)
        } else {
            self.dismissWithCallback {
                handler(action)
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PhotonActionSheetCell.reuseIdentifier, for: indexPath) as! PhotonActionSheetCell
        let action = actions[indexPath.section][indexPath.row]
        cell.tintColor = self.tintColor
        cell.accessibilityIdentifier = action.title
        if action.accessory == .Switch {
            cell.actionSheet = self
        }
        cell.configure(with: action)
        return cell
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = .systemGray4
    }

    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        let cell  = tableView.cellForRow(at: indexPath)
        cell?.contentView.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // If we have multiple sections show a separator for each one except the first.
        if section > 0 {
            return tableView.dequeueReusableHeaderFooterView(withIdentifier: "SeparatorSectionHeader")
        }

        if let title = title {
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: titleHeaderName) as! PhotonActionSheetTitleHeaderView
            header.tintColor = self.tintColor
            header.configure(with: title)
            return header
        }

        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyHeader")
        return view
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: "EmptyHeader")
        return view
    }

    // A height of at least 1 is required to make sure the default header size isnt used when laying out with AutoLayout
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    // A height of at least 1 is required to make sure the default footer size isnt used when laying out with AutoLayout
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            if title != nil {
                return UIConstants.layout.actionSheetTitleHeaderHeight
            } else {
                return 1
            }
        default:
            return UIConstants.layout.actionSheetSeparatorHeaderHeight
        }
    }
}

private class PhotonActionSheetTitleHeaderView: UITableViewHeaderFooterView {
    static let Padding: CGFloat = 12

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .footnote12
        titleLabel.numberOfLines = 1
        titleLabel.textColor = .grey10.withAlphaComponent(0.6)
        return titleLabel
    }()

    lazy var separatorView: UIView = {
        let separatorLine = UIView()
        separatorLine.backgroundColor = .grey10.withAlphaComponent(0.2)
        return separatorLine
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        self.backgroundView = UIView()
        self.backgroundView?.backgroundColor = .clear
        contentView.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(contentView).offset(PhotonActionSheetTitleHeaderView.Padding)
            make.trailing.greaterThanOrEqualTo(contentView)
            make.top.equalTo(contentView).offset(UIConstants.layout.actionSheetTablePadding)
        }

        contentView.addSubview(separatorView)

        separatorView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.top.equalTo(titleLabel.snp.bottom).offset(UIConstants.layout.actionSheetTablePadding)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String) {
        self.titleLabel.text = title
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.titleLabel.text = nil
    }
}

private class PhotonActionSheetSeparator: UITableViewHeaderFooterView {
    private let separatorLineView = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.backgroundView = UIView()
        separatorLineView.backgroundColor = .clear
        contentView.backgroundColor = .grey50.withAlphaComponent(0.5)
        self.contentView.addSubview(separatorLineView)
        separatorLineView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(self)
            make.centerY.equalTo(self)
            make.height.equalTo(0.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public enum PhotonActionSheetCellAccessoryType {
    case Switch
    case Text
    case None
}
