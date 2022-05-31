/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TipsPageViewController: UIViewController {
    enum State {
        case showTips
        case showEmpty(controller: UIViewController)
    }

    private var emptyController: UIViewController?
    private var currentPageController: UIPageViewController?

    private var tipManager: TipManager
    private let tipTappedAction: (TipManager.Tip) -> Void
    private let tapOutsideAction: () -> Void

    private func createPageController() -> UIPageViewController {
        let pageController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.backgroundColor = .clear
        return pageController
    }

    init(
        tipManager: TipManager,
        tipTapped: @escaping (TipManager.Tip) -> Void,
        tapOutsideAction: @escaping () -> Void) {
            self.tipManager = tipManager
            self.tipTappedAction = tipTapped
            self.tapOutsideAction = tapOutsideAction
            super.init(nibName: nil, bundle: nil)
        }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }

    func setupPageController(with state: State) {
        currentPageController?.removeAsChild()
        emptyController?.removeAsChild()

        switch state {
        case .showTips:
            guard let initialVC = tipManager.fetchFirstTip().map({ TipViewController(tip: $0, tipTappedAction: tipTappedAction, tapOutsideAction: tapOutsideAction) }) else { return }
            self.currentPageController = createPageController()
            self.currentPageController.map { install($0, on: self.view) }
            self.currentPageController?.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)

            let pageControl = currentPageController?.view.subviews.first { $0 is UIPageControl } as? UIPageControl
            pageControl?.pageIndicatorTintColor = .primaryText.withAlphaComponent(0.48)
            pageControl?.currentPageIndicatorTintColor = .primaryText

        case .showEmpty(let controller):
            emptyController = controller
            install(controller, on: self.view)
        }

    }
}

extension TipsPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let tip = (viewController as! TipViewController).tip
        return tipManager.getTip(before: tip).map { TipViewController(tip: $0, tipTappedAction: tipTappedAction, tapOutsideAction: tapOutsideAction) }
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let tip = (viewController as! TipViewController).tip
        return tipManager.getTip(after: tip).map { TipViewController(tip: $0, tipTappedAction: tipTappedAction, tapOutsideAction: tapOutsideAction) }
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.tipManager.numberOfTips
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
