// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import SnapKit
import Shared

private struct InstructionsViewControllerUX {
    static let TopPadding = CGFloat(20)
    static let TextFont = UIFont.systemFont(ofSize: UIFont.labelFontSize)
    static let TextColor = UIColor.Photon.Grey60
    static let LinkColor = UIColor.Photon.Blue60
}

protocol InstructionsViewControllerDelegate: AnyObject {
    func instructionsViewControllerDidClose(_ instructionsViewController: InstructionsViewController)
}

private func highlightLink(_ s: NSString, withColor color: UIColor) -> NSAttributedString {
    let start = s.range(of: "<")
    if start.location == NSNotFound {
        return NSAttributedString(string: s as String)
    }

    var s: NSString = s.replacingCharacters(in: start, with: "") as NSString
    let end = s.range(of: ">")
    s = s.replacingCharacters(in: end, with: "") as NSString
    let a = NSMutableAttributedString(string: s as String)
    let r = NSRange(location: start.location, length: end.location-start.location)
    a.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: r)
    return a
}

func setupHelpView(_ view: UIView, introText: String, showMeText: String) {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "emptySync")
    view.addSubview(imageView)
    imageView.snp.makeConstraints { (make) -> Void in
        make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(InstructionsViewControllerUX.TopPadding)
        make.centerX.equalTo(view)
    }

    let label1 = UILabel()
    view.addSubview(label1)
    label1.text = introText
    label1.numberOfLines = 0
    label1.lineBreakMode = .byWordWrapping
    label1.font = InstructionsViewControllerUX.TextFont
    label1.textColor = InstructionsViewControllerUX.TextColor
    label1.textAlignment = .center
    label1.snp.makeConstraints { (make) -> Void in
        make.width.equalTo(250)
        make.top.equalTo(imageView.snp.bottom).offset(InstructionsViewControllerUX.TopPadding)
        make.centerX.equalTo(view)
    }

    let label2 = UILabel()
    view.addSubview(label2)
    label2.numberOfLines = 0
    label2.lineBreakMode = .byWordWrapping
    label2.font = InstructionsViewControllerUX.TextFont
    label2.textColor = InstructionsViewControllerUX.TextColor
    label2.textAlignment = .center
    label2.attributedText = highlightLink(showMeText as NSString, withColor: InstructionsViewControllerUX.LinkColor)
    label2.snp.makeConstraints { (make) -> Void in
        make.width.equalTo(250)
        make.top.equalTo(label1.snp.bottom).offset(InstructionsViewControllerUX.TopPadding)
        make.centerX.equalTo(view)
    }
}

class InstructionsViewController: UIViewController {
    weak var delegate: InstructionsViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.Photon.White100

        navigationItem.leftBarButtonItem = UIBarButtonItem(title: .SendToCloseButton, style: .done, target: self, action: #selector(close))
        navigationItem.leftBarButtonItem?.accessibilityIdentifier = "InstructionsViewController.navigationItem.leftBarButtonItem"

        setupHelpView(view,
            introText: .SendToNotSignedInText,
                showMeText: .SendToNotSignedInMessage)
    }

    @objc func close() {
        delegate?.instructionsViewControllerDidClose(self)
    }

    func showMeHow() {
        print("Show me how") // TODO Not sure what to do or if to keep this. Waiting for UX feedback.
    }
}
