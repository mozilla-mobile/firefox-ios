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
}

class ShortcutView: UIView {
    private var shortcut: Shortcut
    weak var delegate: ShortcutViewDelegate?
    
    lazy var outerView: UIView = {
        let outerView = UIView()
        outerView.backgroundColor = .above
        outerView.layer.cornerRadius = 8
        return outerView
    }()
    
    lazy var innerView: UIView = {
        let innerView = UIView()
        innerView.backgroundColor = .foundation
        innerView.layer.cornerRadius = 4
        return innerView
    }()
    
    lazy var letterLabel: UILabel = {
        let letterLabel = UILabel()
        letterLabel.textColor = .primaryText
        letterLabel.font = .title20
        return letterLabel
    }()
    
    lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.textColor = .primaryText
        nameLabel.font = .footnote12
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
        
        letterLabel.text = ShortcutsManager.shared.firstLetterFor(shortcut: shortcut)
        innerView.addSubview(letterLabel)
        letterLabel.snp.makeConstraints { make in
            make.center.equalTo(innerView)
        }
        
        nameLabel.text = ShortcutsManager.shared.nameFor(shortcut: shortcut)
        addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(outerView.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
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
    
}

extension ShortcutView: UIContextMenuInteractionDelegate {
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil,
                                          actionProvider: { _ in
            
            let removeFromShortcutsAction = UIAction(title: UIConstants.strings.removeFromShortcuts,
                                                     image: UIImage(named: "icon_shortcuts_remove"),
                                                     attributes: .destructive) { _ in
                guard self == self else { return }
                let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                feedbackGenerator.prepare()
                CHHapticEngine.capabilitiesForHardware().supportsHaptics ? feedbackGenerator.impactOccurred() : AudioServicesPlaySystemSound(1519)
                self.delegate?.removeFromShortcutsAction(shortcut: self.shortcut)
            }
            return UIMenu(children: [removeFromShortcutsAction])
        })
    }
}
