/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol WelcomeTourDelegate: AnyObject {
    func welcomeTourDidFinish(_ tour: WelcomeTour)
}

final class WelcomeTour: UIViewController,  NotificationThemeable {

    private weak var navStack: UIStackView!
    private weak var labelStack: UIStackView!
    private weak var titleLabel: UILabel!
    private weak var textLabel: UILabel!
    private weak var backButton: UIButton!
    private weak var skipButton: UIButton!
    private weak var pageControl: UIPageControl!
    private weak var ctaButton: UIButton!
    private weak var waves: UIImageView!
    private weak var container: UIView!
    private weak var imageView: UIImageView!

    // references to animated constraints
    private weak var labelLeft: NSLayoutConstraint!
    private weak var labelRight: NSLayoutConstraint!
    private var margin: CGFloat {
        return view.traitCollection.userInterfaceIdiom == .phone ? 16 : 112
    }

    // model
    private var steps: [Step]!
    private var current: Step?
    private weak var delegate: WelcomeTourDelegate?

    init(delegate: WelcomeTourDelegate) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationCapturesStatusBarAppearance = true
        self.delegate = delegate
        steps = Step.all
    }

    required init?(coder: NSCoder) { return nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        addStaticViews()
        addDynamicViews()
        applyTheme()

        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: .DisplayThemeChanged, object: nil)
    }

    private func addStaticViews() {
        let navStack = UIStackView()
        navStack.translatesAutoresizingMaskIntoConstraints = false
        navStack.axis = .horizontal
        navStack.distribution = .equalCentering
        navStack.alignment = .center
        view.addSubview(navStack)
        self.navStack = navStack

        navStack.heightAnchor.constraint(equalToConstant: 44).isActive = true
        navStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        navStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        navStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

        let backButton = UIButton.systemButton(with: .init(named: "backChevron")!, target: self, action: #selector(back))
        navStack.addArrangedSubview(backButton)
        backButton.widthAnchor.constraint(equalToConstant: 44).isActive = true
        navStack.addArrangedSubview(backButton)
        self.backButton = backButton

        let pageControl = UIPageControl()
        pageControl.isUserInteractionEnabled = false
        pageControl.numberOfPages = 4
        pageControl.currentPage = 0
        pageControl.setContentHuggingPriority(.defaultLow, for: .horizontal)
        pageControl.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        navStack.addArrangedSubview(pageControl)
        self.pageControl = pageControl

        let centerControl = pageControl.centerXAnchor.constraint(equalTo: navStack.centerXAnchor)
        centerControl.priority = .defaultHigh
        centerControl.isActive = true

        let skipButton = UIButton(type: .system)
        skipButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 74).isActive = true
        skipButton.addTarget(self, action: #selector(skip), for: .primaryActionTriggered)
        skipButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        navStack.addArrangedSubview(skipButton)
        skipButton.setTitle(.localized(.skip), for: .normal)
        skipButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        skipButton.titleLabel?.adjustsFontForContentSizeCategory = true

        self.skipButton = skipButton

        let waves = UIImageView(image: .init(named: "onboardingWaves"))
        waves.translatesAutoresizingMaskIntoConstraints = false
        waves.setContentHuggingPriority(.required, for: .vertical)
        view.addSubview(waves)
        self.waves = waves

        waves.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        waves.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        waves.heightAnchor.constraint(equalToConstant: 37).isActive = true
        waves.bottomAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 208).isActive = true
        let wavesBottom = waves.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 208)
        wavesBottom.priority = .defaultHigh
        wavesBottom.isActive = true
    }

    private func addDynamicViews() {
        let labelStack = UIStackView()
        labelStack.translatesAutoresizingMaskIntoConstraints = false
        labelStack.axis = .vertical
        labelStack.distribution = .fill
        labelStack.alignment = .leading
        labelStack.spacing = 8
        labelStack.alpha = 0
        view.addSubview(labelStack)
        self.labelStack = labelStack

        let labelLeft = labelStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: margin + 48)
        labelLeft.priority = .init(rawValue: 999)
        labelLeft.isActive = true
        self.labelLeft = labelLeft

        let labelRight = labelStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -margin + 48)
        labelRight.priority = .init(rawValue: 999)
        labelRight.isActive = true
        self.labelRight = labelRight

        labelStack.topAnchor.constraint(equalTo: navStack.bottomAnchor, constant: 24).isActive = true
        labelStack.bottomAnchor.constraint(lessThanOrEqualTo: waves.topAnchor).isActive = true

        let titleLabel = UILabel()
        titleLabel.text = steps.first?.title
        titleLabel.numberOfLines = 0
        titleLabel.font = .preferredFont(forTextStyle: .title2).bold()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        labelStack.addArrangedSubview(titleLabel)
        self.titleLabel = titleLabel

        let textLabel = UILabel()
        textLabel.text = steps.first?.text
        textLabel.numberOfLines = 3
        textLabel.font = .preferredFont(forTextStyle: .body)
        textLabel.adjustsFontForContentSizeCategory = true
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        textLabel.setContentHuggingPriority(.required, for: .vertical)

        labelStack.addArrangedSubview(textLabel)
        self.textLabel = textLabel

        let ctaButton = UIButton(type: .system)
        ctaButton.setTitle(.localized(.continueMessage), for: .normal)
        ctaButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        ctaButton.titleLabel?.adjustsFontForContentSizeCategory = true
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.addTarget(self, action: #selector(forward), for: .primaryActionTriggered)
        ctaButton.alpha = 0
        view.addSubview(ctaButton)
        self.ctaButton = ctaButton

        ctaButton.layer.cornerRadius = 24
        ctaButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        ctaButton.leadingAnchor.constraint(equalTo: labelStack.leadingAnchor).isActive = true
        ctaButton.trailingAnchor.constraint(equalTo: labelStack.trailingAnchor).isActive = true
        ctaButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true

        let imageView = UIImageView(image: .init(named: "tour1"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        view.insertSubview(imageView, belowSubview: waves)
        self.imageView = imageView
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.topAnchor.constraint(equalTo: waves.topAnchor).isActive = true
        imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(container, belowSubview: waves)
        self.container = container

        container.leadingAnchor.constraint(equalTo: labelStack.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: labelStack.trailingAnchor).isActive = true
        container.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        container.topAnchor.constraint(equalTo: waves.topAnchor).isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if current == nil {
            startTour()
        }
    }

    private func startTour() {
        let first = steps.first!
        display(step: first)
    }

    private func display(step: Step) {
        current = step
        pageControl.currentPage = steps.firstIndex(where: { $0 === step }) ?? 0

        let title: String = isLastStep() ? .localized(.finishTour) : .localized(.continueMessage)

        // No image transition and "move right" for first step
        let duration: CGFloat = isFirstStep() ? 0 : 0.3

        // Image transition
        UIView.transition(with: imageView, duration: duration, options: .transitionCrossDissolve, animations: {
            self.imageView.image = UIImage(named: step.background.image)
            self.imageView.backgroundColor = step.background.color ?? .clear
            if self.traitCollection.userInterfaceIdiom == .phone {
                self.imageView.contentMode = step.background.color == nil ? .scaleAspectFill : .scaleAspectFit
            }
        })

        // Move and Fade transition
        UIView.animate(withDuration: duration) {
            self.moveRight()
            self.labelStack.alpha = 0
            self.ctaButton.alpha = 0
            self.container.alpha = 0
            self.view.layoutIfNeeded()
        } completion: { _ in

            self.fillContainer(with: step.content)
            self.ctaButton.setTitle(title, for: .normal)

            UIView.animate(withDuration: 0.3) {
                self.moveLeft()
                self.titleLabel.text = step.title
                self.textLabel.text = step.text
                self.labelStack.alpha = 1
                self.ctaButton.alpha = 1
                self.container.alpha = 1
                self.view.layoutIfNeeded()
            }
        }
    }

    private func moveRight() {
        labelLeft.constant = margin + 48
        labelRight.constant = -margin + 48
    }

    private func moveLeft() {
        labelLeft.constant = margin
        labelRight.constant = -margin
    }

    private func fillContainer(with content: UIView?) {
        container.subviews.forEach({ $0.removeFromSuperview() })

        guard let content = content else { return }
        (content as? NotificationThemeable)?.applyTheme()
        container.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        content.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        content.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        content.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true
        container.setNeedsLayout()
        container.layoutIfNeeded()
    }

    // MARK: Actions
    @objc func back() {
        guard !isFirstStep() else {
            dismiss(animated: true, completion: nil)
            return
        }
        display(step: steps[currentIndex - 1])
    }

    @objc func forward() {
        guard !isLastStep() else {
            skip()
            return
        }
        display(step: steps[currentIndex + 1])
    }

    @objc func skip() {
        delegate?.welcomeTourDidFinish(self)
    }

    // MARK: Helper
    private var currentIndex: Int {
        guard let current = current else { return 0 }
        let index = steps.firstIndex(where: { $0 === current }) ?? 0
        return index
    }

    private func isFirstStep() -> Bool {
        return currentIndex == 0
    }

    private func isLastStep() -> Bool {
        return currentIndex + 1 >= steps.count
    }

    // MARK: Theming
    func applyTheme() {
        view.backgroundColor = .theme.ecosia.welcomeBackground
        waves.tintColor = .theme.ecosia.welcomeBackground
        titleLabel.textColor = .theme.ecosia.primaryText
        textLabel.textColor = .theme.ecosia.secondaryText
        skipButton.tintColor = .theme.ecosia.primaryButton
        backButton.tintColor = .theme.ecosia.primaryButton
        pageControl.pageIndicatorTintColor = .theme.ecosia.disabled
        pageControl.currentPageIndicatorTintColor = .theme.ecosia.primaryButton
        ctaButton.backgroundColor = .Light.Button.secondary
        ctaButton.setTitleColor(.Light.Text.primary, for: .normal)
        container.subviews.forEach({ ($0 as? NotificationThemeable)?.applyTheme() })

        imageView.backgroundColor = current?.background.color ?? .clear
        guard let current = current else { return }
        imageView.image = .init(named: current.background.image)
    }

    @objc func themeChanged() {
        applyTheme()
    }
}
