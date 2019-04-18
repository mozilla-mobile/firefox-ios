/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

class SyncMenuButton: UIButton {
    let syncManager: SyncManager
    let iconSize = CGSize(width: 24, height: 24)
    let normalImage: UIImage
    let syncingImage: UIImage

    init(with syncManager: SyncManager) {
        self.syncManager = syncManager

        let image = UIImage(named: "FxA-Sync")!.createScaled(iconSize)
        self.normalImage = ThemeManager.instance.currentName == .dark ? image.tinted(withColor: .white) : image
        self.syncingImage = UIImage(named: "FxA-Sync-Blue")!.createScaled(iconSize)

        super.init(frame: .zero)

        self.addTarget(self, action: #selector(startSync), for: .touchUpInside)

        let line = UIView()
        line.backgroundColor = UIColor.Photon.Grey40
        self.addSubview(line)
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.leading.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        guard let syncStatus = syncManager.syncDisplayState else {
            setImage(self.normalImage, for: [])
            return
        }

        if syncStatus == .inProgress {
            setImage(self.syncingImage, for: [])
            animate()
        } else {
            setImage(self.normalImage, for: [])
        }
    }

    private func animate() {
        let continuousRotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        continuousRotateAnimation.fromValue = 0.0
        continuousRotateAnimation.toValue = CGFloat(Double.pi)
        continuousRotateAnimation.isRemovedOnCompletion = true
        continuousRotateAnimation.duration = 0.5
        continuousRotateAnimation.repeatCount = .infinity
        self.imageView?.layer.add(continuousRotateAnimation, forKey: "rotateKey")
    }

    func updateAnimations() {
        self.imageView?.layer.removeAllAnimations()
        setImage(self.normalImage, for: [])
        if let syncStatus = syncManager.syncDisplayState, syncStatus == .inProgress {
            setImage(self.syncingImage, for: [])
            animate()
        }
    }

    @objc func startSync() {
        self.syncManager.syncEverything(why: .syncNow)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

