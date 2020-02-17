/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

class LibraryPanelButton: UIButton {
    var nameLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLibraryPanel()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func setupLibraryPanel() {

        // For iPhone 5 screen, don't show the button labels
        if DeviceInfo.screenSizeOrientationIndependent().width > 320 {
            let currentDeviceType = UIDevice.current.userInterfaceIdiom
            if currentDeviceType == .phone {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 14, right: 0)
            } else {
                imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
            }
            addSubview(nameLabel)
            nameLabel.snp.makeConstraints { make in
                if currentDeviceType == .phone {
                    // On phone screen move the label up slightly off the bottom
                    make.bottom.equalToSuperview().inset(4)
                } else {
                    // On the iPad, move the label up slightly
                    make.bottom.equalToSuperview().inset(2)
                }

                make.centerX.equalToSuperview()
                make.width.equalToSuperview()
            }
            nameLabel.adjustsFontSizeToFitWidth = true
            nameLabel.minimumScaleFactor = 0.7
            nameLabel.numberOfLines = 1
            nameLabel.font = UIFont.systemFont(ofSize: DynamicFontHelper.defaultHelper.DefaultSmallFontSize - 1)
            nameLabel.textAlignment = .center
        }
    }
}
