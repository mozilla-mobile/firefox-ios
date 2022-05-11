/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import DesignSystem

public protocol ShortcutViewDelegate: AnyObject {
    func shortcutTapped(shortcut: Shortcut)
    func removeFromShortcutsAction(shortcut: Shortcut)
    func rename(shortcut: Shortcut)
    func dismissShortcut()
}

public class ShortcutView: UIView {
    public var contextMenuIsDisplayed = false
    public private(set) var shortcut: Shortcut
    public weak var delegate: ShortcutViewDelegate?

    public private(set) lazy var outerView: UIView = {
        let outerView = UIView()
        outerView.backgroundColor = .above
        outerView.layer.cornerRadius = 8
        return outerView
    }()

    private lazy var innerView: UIView = {
        let innerView = UIView()
        innerView.backgroundColor = .foundation
        innerView.layer.cornerRadius = 4
        return innerView
    }()

    private lazy var letterLabel: UILabel = {
        let letterLabel = UILabel()
        letterLabel.textColor = .primaryText
        letterLabel.font = .title20
        return letterLabel
    }()

    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = .primaryText
        nameLabel.font = .footnote12
        nameLabel.numberOfLines = 2
        nameLabel.textAlignment = .center
        return nameLabel
    }()

    public struct LayoutConfiguration {
        public var width: CGFloat
        public var height: CGFloat
        public var inset: CGFloat

        public static let iPad = LayoutConfiguration(
            width: .shortcutViewWidthIPad,
            height: .shortcutViewHeightIPad,
            inset: .shortcutViewInnerDimensionIPad
        )
        public static let `default` = LayoutConfiguration(
            width: .shortcutViewWidth,
            height: .shortcutViewHeight,
            inset: .shortcutViewInnerDimension
        )
    }

    public init(shortcut: Shortcut, layoutConfiguration: LayoutConfiguration) {
        self.shortcut = shortcut

        super.init(frame: CGRect.zero)
        self.frame = CGRect(x: 0, y: 0, width: layoutConfiguration.width, height: layoutConfiguration.height)

        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.addGestureRecognizer(tap)

        addSubview(outerView)
        outerView.snp.makeConstraints { make in
            make.width.height.equalTo(layoutConfiguration.width)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }

        outerView.addSubview(innerView)
        innerView.snp.makeConstraints { make in
            make.width.height.equalTo(layoutConfiguration.inset)
            make.center.equalTo(outerView)
        }

        letterLabel.text = shortcut.name.first.map(String.init)?.capitalized
        innerView.addSubview(letterLabel)
        letterLabel.snp.makeConstraints { make in
            make.center.equalTo(innerView)
        }

        nameLabel.text = shortcut.name
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(outerView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview().offset(8)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func didTap() {
        delegate?.shortcutTapped(shortcut: shortcut)
    }

    public func rename(shortcut: Shortcut) {
        self.shortcut = shortcut
        nameLabel.text = shortcut.name
        letterLabel.text = shortcut.name.first.map(String.init)?.capitalized
    }
}

// MARK: Constants

fileprivate extension CGFloat {
    static let shortcutViewWidth: CGFloat = 60
    static let shortcutViewWidthIPad: CGFloat = 80
    static let shortcutViewInnerDimension: CGFloat = 36
    static let shortcutViewInnerDimensionIPad: CGFloat = 48
    static let shortcutViewHeight: CGFloat = 84
    static let shortcutViewHeightIPad: CGFloat = 100
}
