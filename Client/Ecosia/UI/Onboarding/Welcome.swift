/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

protocol WelcomeDelegate: AnyObject {
    func welcomeDidFinish(_ welcome: Welcome)
}

final class Welcome: UIViewController {
    private weak var logo: UIImageView!
    private weak var background: UIImageView!
    private weak var overlay: UIView!
    private weak var overlayLogo: UIImageView!
    private var maskLayer: CALayer!
    private weak var stack: UIStackView!

    private var logoCenterConstraint: NSLayoutConstraint!
    private var logoTopConstraint: NSLayoutConstraint!
    private var logoHeightConstraint: NSLayoutConstraint!
    private var stackBottonConstraint: NSLayoutConstraint!
    private var stackTopConstraint: NSLayoutConstraint!

    private var zoomedOut = false
    private weak var delegate: WelcomeDelegate?

    required init?(coder: NSCoder) { nil }
    init(delegate: WelcomeDelegate) {
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
        definesPresentationContext = true
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return zoomedOut ? .lightContent : .darkContent
    }

    // MARK: Views
    override func viewDidLoad() {
        super.viewDidLoad()

        addOverlay()
        addBackground()
        addStack()

        if LegacyThemeManager.instance.systemThemeIsOn {
            let userInterfaceStyle = traitCollection.userInterfaceStyle
            LegacyThemeManager.instance.current = userInterfaceStyle == .dark ? LegacyDarkTheme() : LegacyNormalTheme()
        }

        Task.detached {
            // Fetching FinancialReports async as some onboarding steps might use it
            try? await FinancialReports.shared.fetchAndUpdate()
        }
    }

    private var didAppear = false
    override func viewDidAppear(_ animated: Bool) {
        guard !didAppear else { return }
        addMask()
        fadeIn()
        didAppear = true
        Analytics.shared.introDisplaying(page: .start, at: 0)
    }

    private func addOverlay() {
        let overlay = UIView()
        overlay.backgroundColor = .init(named: "splash")
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        self.overlay = overlay

        overlay.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        overlay.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        overlay.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let overlayLogo = UIImageView(image: .init(named: "ecosiaLogoLaunch")?.withRenderingMode(.alwaysTemplate))
        overlayLogo.translatesAutoresizingMaskIntoConstraints = false
        overlayLogo.contentMode = .scaleAspectFit
        overlayLogo.tintColor = .init(named: "splashLogoTint")
        overlay.addSubview(overlayLogo)
        self.overlayLogo = overlayLogo

        overlayLogo.centerXAnchor.constraint(equalTo: overlay.centerXAnchor).isActive = true
        overlayLogo.centerYAnchor.constraint(equalTo: overlay.centerYAnchor).isActive = true
        overlayLogo.heightAnchor.constraint(equalToConstant: 72).isActive = true
    }

    private func addBackground() {
        let background = UIImageView(image: .init(named: "forest"))
        background.translatesAutoresizingMaskIntoConstraints = false
        background.contentMode = .scaleAspectFill
        view.addSubview(background)
        background.alpha = 0
        self.background = background

        background.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        background.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        background.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        background.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let logo = UIImageView(image: .init(named: "ecosiaLogoLaunch")?.withRenderingMode(.alwaysTemplate))
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.contentMode = .scaleAspectFit
        logo.tintColor = .white
        logo.isAccessibilityElement = true
        logo.accessibilityIdentifier = AccessibilityIdentifiers.Ecosia.logo
        logo.accessibilityLabel = .localized(.ecosiaLogoAccessibilityLabel)
        background.addSubview(logo)
        self.logo = logo

        logoCenterConstraint = logo.centerYAnchor.constraint(equalTo: background.centerYAnchor)
        logoCenterConstraint.priority = .defaultHigh
        logoCenterConstraint.isActive = true
        logoTopConstraint = logo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        logoTopConstraint.priority = .defaultHigh
        logoTopConstraint.isActive = false
        logo.centerXAnchor.constraint(equalTo: background.centerXAnchor).isActive = true

        logoHeightConstraint = logo.heightAnchor.constraint(equalToConstant: 72)
        logoHeightConstraint.priority = .defaultHigh
        logoHeightConstraint.isActive = true
    }

    private func addStack() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
        stack.axis = .vertical
        stack.distribution = .fill
        stack.alignment = .fill
        stack.spacing = 10
        view.addSubview(stack)
        self.stack = stack

        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = introText
        label.accessibilityLabel = simplestWayString.replacingOccurrences(of: "\n", with: "")
        label.font = .preferredFont(forTextStyle: .largeTitle).bold()
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .white
        stack.addArrangedSubview(label)

        let cta = UIButton(type: .system)
        cta.backgroundColor = .Light.Button.secondary
        cta.setTitle(.localized(.getStarted), for: .normal)
        cta.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        cta.titleLabel?.adjustsFontForContentSizeCategory = true
        cta.setTitleColor(.Light.Text.primary, for: .normal)
        cta.layer.cornerRadius = 25
        cta.heightAnchor.constraint(equalToConstant: 50).isActive = true
        cta.addTarget(self, action: #selector(getStarted), for: .primaryActionTriggered)

        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(UIView())
        stack.addArrangedSubview(cta)

        let skipButton = UIButton(type: .system)
        skipButton.backgroundColor = .clear
        skipButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        skipButton.titleLabel?.adjustsFontForContentSizeCategory = true
        skipButton.setTitleColor(.Dark.Text.secondary, for: .normal)
        skipButton.setTitle(.localized(.skipWelcomeTour), for: .normal)
        skipButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        skipButton.addTarget(self, action: #selector(skip), for: .primaryActionTriggered)

        stack.addArrangedSubview(skipButton)

        if view.traitCollection.userInterfaceIdiom == .phone {
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        } else {
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            stack.widthAnchor.constraint(equalToConstant: 544).isActive = true
        }
        stackTopConstraint = stack.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -16)
        stackTopConstraint.priority = .defaultHigh
        stackTopConstraint.isActive = true
        stackBottonConstraint = stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        stackBottonConstraint.priority = .defaultHigh
    }

    func addMask() {
        let point = CGPoint(x: logo.frame.midX - 25, y: logo.frame.midY - 13)
        let mask = CGRect(origin: point, size: .init(width: 32, height: 32))

        let layer  = CALayer()
        layer.contents = UIImage(named: "splashMask")?.cgImage
        layer.frame = mask
        layer.opacity = 0
        layer.contentsGravity = .resizeAspect

        background.layer.mask = layer
        maskLayer = layer
        background.alpha = 1.0
    }

    // MARK: Animations
    private func fadeIn() {
        maskLayer.opacity = 1

        CATransaction.begin()
        CATransaction.setAnimationTimingFunction(.init(name: CAMediaTimingFunctionName.easeIn))
        CATransaction.setCompletionBlock { [weak self] in
            self?.zoomOut()
        }

        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 0.0
        anim.toValue = 1.0
        anim.duration = 0.3
        maskLayer.add(anim, forKey: "opacity")

        CATransaction.commit()
    }

    private func zoomOut() {
        zoomedOut = true

        let height = max(view.bounds.height, view.bounds.width)
        let targetFrame = self.view.bounds.inset(by: .init(equalInset: -2.5 * height))

        CATransaction.begin()
        CATransaction.setAnimationDuration(1.4)
        CATransaction.setAnimationTimingFunction(.init(name: CAMediaTimingFunctionName.easeInEaseOut))
        CATransaction.setCompletionBlock { [weak self] in
            self?.showText()
            self?.background.layer.mask = nil
        }
        maskLayer.frame = targetFrame
        CATransaction.commit()
    }

    private func showText() {
        UIView.animate(withDuration: 0.3, delay: 0, options: []) {
            self.logoTopConstraint.isActive = true
            self.logoCenterConstraint.isActive = false
            self.logoHeightConstraint.constant = 48
            self.stack.isHidden = false
            self.stackTopConstraint.isActive = false
            self.stackBottonConstraint.isActive = true
            self.view.layoutIfNeeded()
            self.setNeedsStatusBarAppearanceUpdate()
        } completion: { _ in }
    }

    // MARK: Helper
    private let simplestWayString = String.localized(.theSimplestWay)
    private var introText: NSAttributedString {
        let raw = simplestWayString
        let splits = raw.components(separatedBy: .newlines)

        guard splits.count == 3 else { return NSAttributedString(string: raw) }

        let first = NSMutableAttributedString(string: splits[0])
        let middle = NSMutableAttributedString(string: splits[1])
        let end = NSMutableAttributedString(string: splits[2])

        let image1Attachment = NSTextAttachment()
        image1Attachment.image = UIImage(named: "splashTree1")
        let image1String = NSAttributedString(attachment: image1Attachment)

        let image2Attachment = NSTextAttachment()
        image2Attachment.image = UIImage(named: "splashTree2")
        let image2String = NSAttributedString(attachment: image2Attachment)

        first.append(image1String)
        first.append(middle)
        first.append(image2String)
        first.append(end)
        return first
    }

    // MARK: Actions
    @objc func getStarted() {
        let tour = WelcomeTour(delegate: self)
        tour.modalTransitionStyle = .crossDissolve
        tour.modalPresentationStyle = .overCurrentContext
        present(tour, animated: true, completion: nil)
        Analytics.shared.introClick(.next, page: .start, index: 0)
    }

    @objc func skip() {
        Analytics.shared.introClick(.skip, page: .start, index: 0)
        delegate?.welcomeDidFinish(self)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        LegacyThemeManager.instance.themeChanged(from: previousTraitCollection, to: traitCollection)
    }
}

extension Welcome: WelcomeTourDelegate {
    func welcomeTourDidFinish(_ tour: WelcomeTour) {
        delegate?.welcomeDidFinish(self)
    }
}
