/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ScrollViewController: UIPageViewController, PageControlDelegate {

    private  let cardSlides = ["onboarding_1", "onboarding_2", "onboarding_3"]

    @objc func incrementPage(_ pageControl: PageControl) {
        changePage(isIncrement: true)
    }

    func decrementPage(_ pageControl: PageControl) {
        changePage(isIncrement: false)
    }

    private func changePage(isIncrement: Bool) {
        guard let currentViewController = viewControllers?.first, let nextViewController = isIncrement ?
            dataSource?.pageViewController(self, viewControllerAfter: currentViewController):
            dataSource?.pageViewController(self, viewControllerBefore: currentViewController) else { return }

        guard let newIndex = orderedViewControllers.firstIndex(of: nextViewController) else { return }
        let direction: UIPageViewController.NavigationDirection = isIncrement ? .forward : .reverse

        setViewControllers([nextViewController], direction: direction, animated: true, completion: nil)
        scrollViewControllerDelegate?.scrollViewController(scrollViewController: self, didUpdatePageIndex: newIndex)
    }

    private var slides = [UIImage]()
    private var orderedViewControllers: [UIViewController] = []
    weak var scrollViewControllerDelegate: ScrollViewControllerDelegate?

    override init(transitionStyle style: UIPageViewController.TransitionStyle, navigationOrientation: UIPageViewController.NavigationOrientation, options: [UIPageViewController.OptionsKey: Any]? = nil) {
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        dataSource = self
        delegate = self

        for slideName in cardSlides {
            slides.append(UIImage(named: slideName)!)
        }

        addCard(title: UIConstants.strings.CardTitleWelcome, text: UIConstants.strings.CardTextWelcome, viewController: UIViewController(), image: UIImageView(image: slides[0]))
        addCard(title: UIConstants.strings.CardTitleSearch, text: UIConstants.strings.CardTextSearch, viewController: UIViewController(), image: UIImageView(image: slides[1]))
        addCard(title: UIConstants.strings.CardTitleHistory, text: UIConstants.strings.CardTextHistory, viewController: UIViewController(), image: UIImageView(image: slides[2]))

        if let firstViewController = orderedViewControllers.first {
            setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }

        scrollViewControllerDelegate?.scrollViewController(scrollViewController: self, didUpdatePageCount: orderedViewControllers.count)
    }

    func addCard(title: String, text: String, viewController: UIViewController, image: UIImageView) {
        let introView = UIView()
        let gradientLayer = IntroCardGradientBackgroundView()
        gradientLayer.layer.cornerRadius = UIConstants.layout.introViewCornerRadius

        introView.addSubview(gradientLayer)
        viewController.view.backgroundColor = .clear
        viewController.view.addSubview(introView)

        gradientLayer.snp.makeConstraints { make in
            make.edges.equalTo(introView)
        }

        introView.layer.shadowRadius = UIConstants.layout.introViewShadowRadius
        introView.layer.shadowOpacity = UIConstants.layout.introViewShadowOpacity
        introView.layer.cornerRadius = UIConstants.layout.introViewCornerRadius
        introView.layer.masksToBounds = false

        introView.addSubview(image)
        image.snp.makeConstraints { make in
            make.top.equalTo(introView)
            make.centerX.equalTo(introView)
            make.width.equalTo(UIConstants.layout.introViewImageWidth)
            make.height.equalTo(UIConstants.layout.introViewImageHeight)
        }

        let titleLabel = UILabel()
        titleLabel.numberOfLines = 2
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = UIConstants.layout.introScreenMinimumFontScale
        titleLabel.textColor = .firstRunTitle
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.text = title
        titleLabel.font = .body18

        introView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make ) -> Void in
            make.top.equalTo(image.snp.bottom).offset(UIConstants.layout.introViewTitleLabelOffset)
            make.leading.equalTo(introView).offset(UIConstants.layout.introViewTitleLabelOffset)
            make.trailing.equalTo(introView).inset(UIConstants.layout.introViewTitleLabelInset)
            make.centerX.equalTo(introView)
        }

        let textLabel = UILabel()
        textLabel.numberOfLines = 5
        textLabel.attributedText = attributedStringForLabel(text)
        textLabel.adjustsFontSizeToFitWidth = true
        textLabel.minimumScaleFactor = UIConstants.layout.introScreenMinimumFontScale
        textLabel.lineBreakMode = .byTruncatingTail
        textLabel.textAlignment = .center
        textLabel.textColor = .grey50
        textLabel.font = .footnote14

        introView.addSubview(textLabel)
        textLabel.snp.makeConstraints({ (make) -> Void in
            make.top.equalTo(titleLabel.snp.bottom).offset(UIConstants.layout.introViewTextLabelOffset)
            make.centerX.equalTo(introView)
            make.leading.equalTo(introView).offset(UIConstants.layout.introViewTextLabelPadding)
            make.trailing.equalTo(introView).inset(UIConstants.layout.introViewTextLabelInset)
        })

        introView.snp.makeConstraints { (make) -> Void in
            make.center.equalTo(viewController.view)
            make.width.equalTo(UIConstants.layout.introScreenWidth).priority(.high)
            make.height.equalTo(UIConstants.layout.introScreenHeight)
            make.leading.greaterThanOrEqualTo(viewController.view).offset(UIConstants.layout.introViewOffset).priority(.required)
            make.trailing.lessThanOrEqualTo(viewController.view).offset(UIConstants.layout.introViewOffset).priority(.required)
        }

        let cardButton = UIButton()

        if orderedViewControllers.count == slides.count - 1 {
            cardButton.setTitle(UIConstants.strings.firstRunButton, for: .normal)
            cardButton.setTitleColor(.purple50, for: .normal)
            cardButton.titleLabel?.font = .body16
            cardButton.addTarget(self, action: #selector(ScrollViewController.didTapStartBrowsingButton), for: .touchUpInside)
        } else {
            cardButton.setTitle(UIConstants.strings.NextIntroButtonTitle, for: .normal)
            cardButton.setTitleColor(.purple50, for: .normal)
            cardButton.titleLabel?.font = .body16
            cardButton.addTarget(self, action: #selector(ScrollViewController.incrementPage), for: .touchUpInside)
        }

        introView.addSubview(cardButton)
        introView.bringSubviewToFront(cardButton)
        cardButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(textLabel.snp.bottom).offset(UIConstants.layout.introViewCardButtonOffset).priority(.required)
            make.bottom.equalTo(introView).offset(-UIConstants.layout.introViewOffset).priority(.low)
            make.centerX.equalTo(introView)
        }
        orderedViewControllers.append(viewController)
    }

    @objc func didTapStartBrowsingButton() {
        scrollViewControllerDelegate?.scrollViewController(scrollViewController: self, didDismissSlideDeck: true)
    }

    private func attributedStringForLabel(_ text: String) -> NSMutableAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = UIConstants.layout.cardTextLineHeight
        paragraphStyle.alignment = .center

        let string = NSMutableAttributedString(string: text)
        string.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: string.length))
        return string
    }
}

extension ScrollViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let firstViewController = viewControllers?.first,
            let index = orderedViewControllers.firstIndex(of: firstViewController) {
            scrollViewControllerDelegate?.scrollViewController(scrollViewController: self, didUpdatePageIndex: index)
        }
    }
}

extension ScrollViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }

        let previousIndex = viewControllerIndex - 1

        guard previousIndex >= 0 else {
            return nil
        }

        guard orderedViewControllers.count > previousIndex else {
            return nil
        }

        return orderedViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.firstIndex(of: viewController) else {
            return nil
        }

        let nextIndex = viewControllerIndex + 1

        let orderedViewControllersCount = orderedViewControllers.count

        guard orderedViewControllersCount != nextIndex else {
            return nil
        }

        guard orderedViewControllersCount > nextIndex else {
            return nil
        }

        return orderedViewControllers[nextIndex]
    }
}

protocol ScrollViewControllerDelegate: AnyObject {
    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageCount count: Int)
    func scrollViewController(scrollViewController: ScrollViewController, didUpdatePageIndex index: Int)
    func scrollViewController(scrollViewController: ScrollViewController, didDismissSlideDeck bool: Bool)
}
