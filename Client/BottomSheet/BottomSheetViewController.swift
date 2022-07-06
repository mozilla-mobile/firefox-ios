// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import UIKit
import SnapKit
import Shared

enum BottomSheetState {
    case none
    case partial
    case full
}

protocol BottomSheetDelegate: AnyObject {
    func closeBottomSheet()
    func showBottomToolbar()
}

class BottomSheetViewController: UIViewController, NotificationThemeable {
    // Delegate
    var delegate: BottomSheetDelegate?
    private var currentState: BottomSheetState = .none
    private var isLandscape: Bool {
        return UIWindow.isLandscape
    }
    private var orientationBasedHeight: CGFloat {
        return isLandscape ? DeviceInfo.screenSizeOrientationIndependent().width : DeviceInfo.screenSizeOrientationIndependent().height
    }
    // shows how much bottom sheet should be visible
    // 1 = full, 0.5 = half, 0 = hidden
    // and for landscape we show 0.5 specifier just because of very small height
    private var heightSpecifier: CGFloat {
        let height = orientationBasedHeight
        let heightForTallScreen: CGFloat = height > 850 ? 0.65 : 0.74
        var specifier = height > 668 ? heightForTallScreen : 0.84
        if isLandscape {
            specifier = 0.5
        }
        return specifier
    }
    private var navHeight: CGFloat {
        return navigationController?.navigationBar.frame.height ?? 0
    }
    private var fullHeight: CGFloat {
        return orientationBasedHeight - navHeight
    }
    private var partialHeight: CGFloat {
        return fullHeight * heightSpecifier
    }
    private var maxY: CGFloat {
        return fullHeight - partialHeight
    }
    private var minY: CGFloat {
        return orientationBasedHeight
    }
    private var endedYVal: CGFloat = 0
    private var endedTranslationYVal: CGFloat = 0

    // Container child view controller
    var containerViewController: UIViewController?

    // Views
    private var overlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.50)
        return view
    }()
    private var panView: UIView = {
        let view = UIView()
        return view
    }()

    // MARK: Initializers
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        roundViews()
        initialViewSetup()
        applyTheme()
    }

    // MARK: View setup
    private func initialViewSetup() {
        self.view.backgroundColor = .clear
        self.view.addSubview(overlay)
        overlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        self.view.addSubview(panView)
        panView.snp.makeConstraints { make in
            make.bottom.equalTo(self.view.safeArea.bottom)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(fullHeight)
        }

        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGesture))
        panView.addGestureRecognizer(gesture)
        panView.translatesAutoresizingMaskIntoConstraints = true

        let overlayTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.hideViewWithAnimation))
        overlay.addGestureRecognizer(overlayTapGesture)

        hideView(shouldAnimate: false)
    }

    private func roundViews() {
        panView.layer.cornerRadius = 10
        view.clipsToBounds = true
        panView.clipsToBounds = true
    }

    // MARK: Bottomsheet swipe methods
    private func moveView(state: BottomSheetState) {
        self.currentState = state
        let yVal = state == .full ? navHeight : state == .partial ? maxY : minY
        panView.frame = CGRect(x: 0, y: yVal, width: view.frame.width, height: fullHeight)
    }

    private func moveView(panGestureRecognizer recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let yVal: CGFloat = translation.y
        let startedYVal = endedTranslationYVal + maxY
        let newYVal = currentState == .full ? navHeight + yVal : startedYVal + yVal
        let downYShiftSpecifier: CGFloat = isLandscape ? 0.3 : 0.2

        // top
        guard newYVal >= navHeight else {
            endedTranslationYVal = 0
            return
        }

        // move the frame according to pan gesture
        panView.frame = CGRect(x: 0, y: newYVal, width: view.frame.width, height: fullHeight)

        if recognizer.state == .ended {
            self.endedTranslationYVal = 0
            // moving down
            if newYVal > self.maxY {
                // past middle
                if newYVal > self.maxY + (self.partialHeight * downYShiftSpecifier) {
                    hideView(shouldAnimate: true)
                } else {
                    self.moveView(state: .partial)
                }
            // moving up
            } else if newYVal < self.maxY {
                self.showFullView(shouldAnimate: true)
            }
        }
    }

    @objc func hideView(shouldAnimate: Bool) {
        let closure = {
            self.moveView(state: .none)
            self.view.isUserInteractionEnabled = true
        }
        guard shouldAnimate else {
            closure()
            self.overlay.alpha = 0
            self.view.isHidden = true
            delegate?.showBottomToolbar()
            return
        }
        self.view.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.25) {
            closure()
            self.overlay.alpha = 0
        } completion: { value in
            if value {
                self.view.isHidden = true
                self.delegate?.showBottomToolbar()
                self.containerViewController?.view.removeFromSuperview()
            }
        }
    }

    @objc func showView() {
        if let container = containerViewController {
            panView.addSubview(container.view)
        }
        UIView.animate(withDuration: 0.26, animations: {
            self.moveView(state: self.isLandscape ? .full : .partial)
            self.overlay.alpha = 1
            self.view.isHidden = false
        })
    }

    func showFullView(shouldAnimate: Bool) {
        let closure = {
            self.moveView(state: .full)
            self.overlay.alpha = 1
            self.view.isHidden = false
        }
        guard shouldAnimate else {
            closure()
            return
        }
        UIView.animate(withDuration: 0.26, animations: {
            closure()
        })
    }

    @objc private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        moveView(panGestureRecognizer: recognizer)
    }

    @objc private func hideViewWithAnimation() {
        hideView(shouldAnimate: true)
    }

    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .normal {
            panView.backgroundColor = UIColor.Photon.Grey10
        } else {
            panView.backgroundColor = UIColor.Photon.Grey90
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            let orient = UIWindow.interfaceOrientation
            switch orient {
            case .portrait:
                self.moveView(state: .partial)
            case .landscapeLeft, .landscapeRight:
                self.moveView(state: .full)
            default:
                print("orientation not supported")
            }
        }, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
            self.containerViewController?.view.setNeedsLayout()
        })
    }
}
