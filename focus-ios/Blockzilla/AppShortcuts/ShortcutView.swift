/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import AudioToolbox
import CoreHaptics

protocol ShortcutViewDelegate: AnyObject {
    func shortcutTapped(shortcut: Shortcut)
    func removeFromShortcutsAction(shortcut: Shortcut)
    func rename(shortcut: Shortcut)
    func dismissShortcut()
}

class ShortcutView: UIView {
    var contextMenuIsDisplayed = false
    private(set) var shortcut: Shortcut
    weak var delegate: ShortcutViewDelegate?
    
    private lazy var outerView: UIView = {
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
    
    init(shortcut: Shortcut, isIpad: Bool) {
        let dimension = isIpad ? UIConstants.layout.shortcutViewWidthIPad : UIConstants.layout.shortcutViewWidth
        let innerDimension = isIpad ? UIConstants.layout.shortcutViewInnerDimensionIPad :  UIConstants.layout.shortcutViewInnerDimension
        let height = isIpad ? UIConstants.layout.shortcutViewHeightIPad :  UIConstants.layout.shortcutViewHeight
        self.shortcut = shortcut
        
        super.init(frame: CGRect.zero)
        self.frame = CGRect(x: 0, y: 0, width: dimension, height: height)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        self.addGestureRecognizer(tap)
        
        addSubview(outerView)
        outerView.snp.makeConstraints { make in
            make.width.height.equalTo(dimension)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
        }
        
        outerView.addSubview(innerView)
        innerView.snp.makeConstraints { make in
            make.width.height.equalTo(innerDimension)
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
        
        let interaction = UIContextMenuInteraction(delegate: self)
        outerView.addInteraction(interaction)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func didTap() {
        delegate?.shortcutTapped(shortcut: shortcut)
    }
    
    func renameShortcut(with shortcut: Shortcut) {
        self.shortcut = shortcut
        nameLabel.text = shortcut.name
        letterLabel.text = shortcut.name.first.map(String.init)?.capitalized
    }
    
}

extension ShortcutView: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: { _ in
            let renameAction = UIAction(
                title: UIConstants.strings.renameShortcut,
                image: .renameShortcut) { _ in
                    self.delegate?.rename(shortcut: self.shortcut)
                }
            
            let removeFromShortcutsAction = UIAction(
                title: UIConstants.strings.removeFromShortcuts,
                image: .removeShortcut,
                attributes: .destructive) { _ in
                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                    feedbackGenerator.prepare()
                    CHHapticEngine.capabilitiesForHardware().supportsHaptics ? feedbackGenerator.impactOccurred() : AudioServicesPlaySystemSound(1519)
                    self.delegate?.removeFromShortcutsAction(shortcut: self.shortcut)
                }
            return UIMenu(children: [removeFromShortcutsAction, renameAction])
        })
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        contextMenuIsDisplayed =  true
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        contextMenuIsDisplayed = false
        self.delegate?.dismissShortcut()
    }
}
