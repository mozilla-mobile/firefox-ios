/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Shared

struct IntroUX {
    static let Width = 375
    static let Height = 667
    static let MinimumFontScale: CGFloat = 0.5
    static let PagerCenterOffsetFromScrollViewBottom = UIScreen.main.bounds.width <= 320 ? 20 : 30
    static let StartBrowsingButtonColor = UIColor.Defaults.Blue40
    static let StartBrowsingButtonHeight = 56
    static let SignInButtonColor = UIColor.Defaults.Blue40
    static let SignInButtonHeight = 60
    static let PageControlHeight = 40
    static let SignInButtonWidth = 290
    static let CardTextWidth = UIScreen.main.bounds.width <= 320 ? 240 : 280
    static let FadeDuration = 0.25
}

protocol IntroViewControllerDelegate: class {
    func introViewControllerDidFinish(_ introViewController: IntroViewController, requestToLogin: Bool)
}

class IntroViewController: UIViewController {
    weak var delegate: IntroViewControllerDelegate?

    // We need to hang on to views so we can animate and change constraints as we scroll
    var cardViews = [CardView]()
    var cards = IntroCard.defaultCards()

    lazy fileprivate var startBrowsingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.clear
        button.setTitle(Strings.StartBrowsingButtonTitle, for: UIControlState())
        button.setTitleColor(IntroUX.StartBrowsingButtonColor, for: UIControlState())
        button.addTarget(self, action: #selector(IntroViewController.startBrowsing), for: UIControlEvents.touchUpInside)
        button.accessibilityIdentifier = "IntroViewController.startBrowsingButton"
        return button
    }()

    lazy var pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.3)
        pc.currentPageIndicatorTintColor = UIColor.black
        pc.accessibilityIdentifier = "IntroViewController.pageControl"
        pc.addTarget(self, action: #selector(IntroViewController.changePage), for: UIControlEvents.valueChanged)
        return pc
    }()

    lazy fileprivate var scrollView: UIScrollView = {
        let sc = UIScrollView()
        sc.backgroundColor = UIColor.clear
        sc.accessibilityLabel = NSLocalizedString("Intro Tour Carousel", comment: "Accessibility label for the introduction tour carousel")
        sc.delegate = self
        sc.bounces = false
        sc.isPagingEnabled = true
        sc.showsHorizontalScrollIndicator = false
        sc.accessibilityIdentifier = "IntroViewController.scrollView"
        return sc
    }()

    var horizontalPadding: Int {
        return self.view.frame.width <= 320 ? 20 : 50
    }

    var verticalPadding: CGFloat {
        return self.view.frame.width <= 320 ? 10 : 38
    }

    lazy fileprivate var imageViewContainer: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        return sv
    }()

    // Because a stackview cannot have a background color
    fileprivate var imagesBackgroundView = UIView()

    override func viewDidLoad() {
        if AppConstants.MOZ_LP_INTRO {
            syncViaLP()
        }

        assert(cards.count > 0, "Intro is empty. At least 1 card is required")
        view.backgroundColor = UIColor.white

        // Add Views
        view.addSubview(pageControl)
        view.addSubview(scrollView)
        view.addSubview(startBrowsingButton)
        scrollView.addSubview(imagesBackgroundView)
        scrollView.addSubview(imageViewContainer)

        // Setup constraints
        imagesBackgroundView.snp.makeConstraints { make in
            make.edges.equalTo(imageViewContainer)
        }
        imageViewContainer.snp.makeConstraints { make in
            make.top.equalTo(self.view)
            make.height.equalTo(self.view.snp.width)
        }
        startBrowsingButton.snp.makeConstraints { make in
            make.left.right.equalTo(self.view)
            make.bottom.equalTo(self.view.safeArea.bottom)
            make.height.equalTo(IntroUX.StartBrowsingButtonHeight)
        }
        scrollView.snp.makeConstraints { make in
            make.left.right.top.equalTo(self.view)
            make.bottom.equalTo(startBrowsingButton.snp.top)
        }
      
        pageControl.snp.makeConstraints { make in
            make.centerX.equalTo(self.scrollView)
            make.centerY.equalTo(self.startBrowsingButton.snp.top).offset(-IntroUX.PagerCenterOffsetFromScrollViewBottom)
        }

        cardViews = cards.flatMap { addIntro(card: $0) }
        pageControl.numberOfPages = cardViews.count
        pageControl.addTarget(self, action: #selector(changePage), for: .valueChanged)

        if let firstCard = cardViews.first {
            setActive(firstCard, forPage: 0)
        }
        setupDynamicFonts()
    }

    func syncViaLP() {
        LeanPlumClient.shared.introScreenVars?.onValueChanged({
            guard let newIntro = LeanPlumClient.shared.introScreenVars?.object(forKey: nil) as? [[String: Any]] else {
                return
            }
            let decoder = JSONDecoder()
            let newCards = newIntro.flatMap { (obj) -> IntroCard? in
                guard let object = try? JSONSerialization.data(withJSONObject: obj, options: []) else {
                    return nil
                }
                let card = try? decoder.decode(IntroCard.self, from: object)
                // Make sure the selector actually goes somewhere. Otherwise dont show that slide
                if let selectorString = card?.buttonSelector {
                    return self.responds(to: NSSelectorFromString(selectorString)) ? card : nil
                } else {
                    return card
                }
            }
            if newCards.count != 0 {
                self.cards = newCards
                for (card, cardView) in zip(self.cards, self.cardViews) {
                    cardView.configureWith(card: card)
                }
            }
        })
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.contentSize = imageViewContainer.frame.size
    }

    func addIntro(card: IntroCard) -> CardView? {
        guard let image = UIImage(named: card.imageName) else {
            return nil
        }
        let imageView = UIImageView(image: image)
        imageViewContainer.addArrangedSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.height.equalTo(imageViewContainer.snp.height)
            make.width.equalTo(imageViewContainer.snp.height)
        }


        let cardView = CardView(verticleSpacing: verticalPadding)
        cardView.configureWith(card: card)
        if let selectorString = card.buttonSelector, self.responds(to: NSSelectorFromString(selectorString)) {
            cardView.button.addTarget(self, action: NSSelectorFromString(selectorString), for: .touchUpInside)
            cardView.button.snp.makeConstraints { make in
                make.width.equalTo(IntroUX.CardTextWidth)
                make.height.equalTo(IntroUX.SignInButtonHeight)
            }
        }
        self.view.addSubview(cardView)
        cardView.snp.makeConstraints { make in
            make.top.equalTo(self.imageViewContainer.snp.bottom).offset(verticalPadding)
            make.bottom.equalTo(self.startBrowsingButton.snp.top)
            make.left.right.equalTo(self.view).inset(horizontalPadding)
        }
        return cardView
    }

    func startBrowsing() {
        delegate?.introViewControllerDidFinish(self, requestToLogin: false)
        LeanPlumClient.shared.track(event: .dismissedOnboarding, withParameters: ["dismissedOnSlide": pageControl.currentPage as AnyObject])

    }

    func login() {
        delegate?.introViewControllerDidFinish(self, requestToLogin: true)
        LeanPlumClient.shared.track(event: .dismissedOnboardingShowLogin, withParameters: ["dismissedOnSlide": pageControl.currentPage as AnyObject])
    }

    func changePage() {
        let swipeCoordinate = CGFloat(pageControl.currentPage) * scrollView.frame.size.width
        scrollView.setContentOffset(CGPoint(x: swipeCoordinate, y: 0), animated: true)
    }

    fileprivate func setActive(_ introView: UIView, forPage page: Int) {
        guard introView.alpha != 1 else {
            return
        }

        UIView.animate(withDuration: IntroUX.FadeDuration, animations: { _ in
            self.cardViews.forEach { $0.alpha = 0.0 }
            introView.alpha = 1.0
            self.pageControl.currentPage = page
        }, completion: nil)
    }
}

// UIViewController setup
extension IntroViewController {
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var shouldAutorotate: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // This actually does the right thing on iPad where the modally
        // presented version happily rotates with the iPad orientation.
        return .portrait
    }
}

// Dynamic Font Helper
extension IntroViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(dynamicFontChanged), name: .DynamicFontChanged, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .DynamicFontChanged, object: nil)
    }

    func dynamicFontChanged(_ notification: Notification) {
        guard notification.name == .DynamicFontChanged else { return }
        setupDynamicFonts()
    }

    fileprivate func setupDynamicFonts() {
        startBrowsingButton.titleLabel?.font = UIFont(name: "FiraSans-Regular", size: DynamicFontHelper.defaultHelper.IntroStandardFontSize)
        cardViews.forEach { cardView in
            cardView.titleLabel.font = UIFont(name: "FiraSans-Medium", size: DynamicFontHelper.defaultHelper.IntroBigFontSize)
            cardView.textLabel.font = UIFont(name: "FiraSans-UltraLight", size: DynamicFontHelper.defaultHelper.IntroStandardFontSize)
        }
    }
}

extension IntroViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        // Need to add this method so that when forcibly dragging, instead of letting deceleration happen, should also calculate what card it's on.
        // This especially affects sliding to the last or first cards.
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        // Need to add this method so that tapping the pageControl will also change the card texts.
        // scrollViewDidEndDecelerating waits until the end of the animation to calculate what card it's on.
        scrollViewDidEndDecelerating(scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(scrollView.contentOffset.x / scrollView.frame.size.width)
        if let cardView = cardViews[safe: page] {
            setActive(cardView, forPage: page)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maximumHorizontalOffset = scrollView.frame.width
        let currentHorizontalOffset = scrollView.contentOffset.x

        var percentageOfScroll = currentHorizontalOffset / maximumHorizontalOffset
        percentageOfScroll = percentageOfScroll > 1.0 ? 1.0 : percentageOfScroll
        let whiteComponent = UIColor.white.components
        let grayComponent = UIColor(rgb: 0xF2F2F2).components
        let newRed   = (1.0 - percentageOfScroll) * whiteComponent.red   + percentageOfScroll * grayComponent.red
        let newGreen = (1.0 - percentageOfScroll) * whiteComponent.green + percentageOfScroll * grayComponent.green
        let newBlue  = (1.0 - percentageOfScroll) * whiteComponent.blue  + percentageOfScroll * grayComponent.blue
        imagesBackgroundView.backgroundColor = UIColor(red: newRed, green: newGreen, blue: newBlue, alpha: 1.0)
    }
}

// A cardView repersents the text for each page of the intro. It does not include the image.
class CardView: UIView {

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        return stackView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = IntroUX.MinimumFontScale
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(1000, for: .vertical)
        return titleLabel
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.numberOfLines = 5
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = IntroUX.MinimumFontScale
        textLabel.textAlignment = .center
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.setContentHuggingPriority(1000, for: .vertical)
        return textLabel
    }()

    lazy var button: UIButton = {
        let button = UIButton()
        button.backgroundColor = IntroUX.SignInButtonColor
        button.setTitle(Strings.SignInButtonTitle, for: [])
        button.setTitleColor(.white, for: [])
        button.setContentHuggingPriority(1000, for: .vertical)
        button.clipsToBounds = true
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    init(verticleSpacing: CGFloat) {
        super.init(frame: .zero)
        stackView.spacing = verticleSpacing
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(textLabel)
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.leading.trailing.top.equalTo(self)
            make.bottom.lessThanOrEqualTo(self).offset(-IntroUX.PageControlHeight)
        }
        alpha = 0
    }

    func configureWith(card: IntroCard) {
        titleLabel.text = card.title
        textLabel.text = card.text
        if let buttonText = card.buttonText, card.buttonSelector != nil {
            button.setTitle(buttonText, for: .normal)
            addSubview(button)
            button.snp.makeConstraints { make in
                make.bottom.centerX.equalTo(self)
            }
        }
    }

    // Allows the scrollView to scroll while the CardView is in front
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let buttonSV = button.superview {
            return convert(button.frame, from: buttonSV).contains(point)
        }
        return false
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct IntroCard: Codable {
    let title: String
    let text: String
    let buttonText: String?
    let buttonSelector: String? // Selector is a string that is synthisized into a Selector via NSSelectorFromString (for LeanPlum's sake)
    let imageName: String

    init(title: String, text: String, imageName: String, buttonText: String? = nil, buttonSelector: String? = nil) {
        self.title = title
        self.text = text
        self.imageName = imageName
        self.buttonText = buttonText
        self.buttonSelector = buttonSelector
    }

    static func defaultCards() -> [IntroCard] {
        let welcome = IntroCard(title: Strings.CardTitleWelcome, text: Strings.CardTextWelcome, imageName: "tour-Welcome")
        let search = IntroCard(title: Strings.CardTitleSearch, text: Strings.CardTextSearch, imageName: "tour-Search")
        let privateBrowsing = IntroCard(title: Strings.CardTitlePrivate, text: Strings.CardTextPrivate, imageName: "tour-Private")
        let mailTo = IntroCard(title: Strings.CardTitleMail, text: Strings.CardTextMail, imageName: "tour-Mail")
        let sync = IntroCard(title: Strings.CardTitleSync, text: Strings.CardTextSync, imageName: "tour-Sync", buttonText: Strings.SignInButtonTitle, buttonSelector: #selector(IntroViewController.login).description)
        return [welcome, search, privateBrowsing, mailTo, sync]
    }

    /* Codable doesnt allow quick conversion to a dictonary */
    func asDictonary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

extension UIColor {
    var components:(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b, a)
    }
}
