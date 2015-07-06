/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

private var imgViews = WeakList<UIImageView>()
private var instance: LightweightThemeManager? = nil

private var ThemeImageLightnessKey = "themeImageLightness"
private var ThemeImageKey = "themeImage"

public class LightweightThemeImage: UIImageViewAligned {
    init(tintColor: UIColor? = nil) {
        let image = UIImage(named: instance?.profile.prefs.stringForKey(ThemeImageKey) ?? "")
        super.init(image: image)
        self.image = image

        contentMode  = UIViewContentMode.ScaleAspectFill
        alignTop = true
        alignRight = true

        imgViews.insert(self)

        if let tintColor = tintColor {
            let tint = UIView()
            tint.backgroundColor = tintColor
            addSubview(tint)
            tint.snp_makeConstraints() { make in
                make.edges.equalTo(self)
            }
        }
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public class LightweightThemeManager {
    private var profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    private class func getImageLightness(img: UIImage?) {
        if let img = img {
            let lightness = img.getAverageLightness(inRect: CGRectMake(0, 0, img.size.width, min(10, img.size.height)))
            instance?.profile.prefs.setBool(lightness > 0.75, forKey: ThemeImageLightnessKey)
        } else {
            // The default background is black, which is not a light color.
            instance?.profile.prefs.setBool(false, forKey: ThemeImageLightnessKey)
        }
    }

    static var themeImageIsLight: Bool {
        return instance?.profile.prefs.boolForKey(ThemeImageLightnessKey) ?? false
    }

    class func setupInstance(profile: Profile) {
        if instance == nil {
            instance = LightweightThemeManager(profile: profile)
        }
    }

    private class func removeOldThemeImage() {
        if let oldImg = instance?.profile.prefs.stringForKey(ThemeImageKey) {
            NSFileManager.defaultManager().removeItemAtPath(oldImg, error: nil)
        }
    }

    private class func updateViews(img: UIImage?) {
        map(imgViews) { $0.image = img }
    }

    public class func setThemeImageName(imgName: String?) {
        removeOldThemeImage()

        if let name = imgName {
            instance?.profile.prefs.setString(name, forKey: ThemeImageKey)
        }

        var img: UIImage? = UIImage(named: imgName ?? "")
        getImageLightness(img)
        updateViews(img)
    }

    public class func setThemeImage(img: UIImage?) {
        if let file = instance?.profile.files.getAndEnsureDirectory(relativeDir: nil, error: nil)?.stringByAppendingPathComponent(Bytes.generateGUID()) {
            if let data = UIImageJPEGRepresentation(img, 0.8) {
                data.writeToFile(file, atomically: true)
                setThemeImageName(file)
                return
            }
        }

        setThemeImageName(nil)
    }
}
