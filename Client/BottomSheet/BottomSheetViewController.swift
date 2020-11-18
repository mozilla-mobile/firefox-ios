/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit
import Shared

enum BottomSheetState {
    case none
    case partial
    case full
}

protocol BottomSheetDelegate {
    func closeBottomSheet()
    func showBottomToolbar()
}

class BottomSheetViewController: UIViewController, Themeable {
    // Delegate
    var delegate: BottomSheetDelegate?
    
    private var orientationBasedHeight: CGFloat {
        if UIApplication.shared.statusBarOrientation.isLandscape {
            return DeviceInfo.screenSizeOrientationIndependent().width
        }
        return DeviceInfo.screenSizeOrientationIndependent().height
    }
    // Shows how much bottom sheet should be visible
    // 1 = full, 0.5 = half, 0 = hidden
    private var heightSpecifier: CGFloat {
        let height = orientationBasedHeight //screenSize.height
        let heightForTallScreen: CGFloat = height > 850 ? 0.65 : 0.74
        return height > 668 ? heightForTallScreen : 0.84
    }
    private var maxY: CGFloat {
        return orientationBasedHeight - frameHeight
    }
    private var minY: CGFloat {
        return orientationBasedHeight
    }
    private var endedYVal: CGFloat = 0
    private var endedTranslationYVal: CGFloat = 0
    private var isFullyHidden = false
    private var isFullyShown = false
    private var frameHeight: CGFloat {
        return orientationBasedHeight * heightSpecifier
    }
    private var navHeight: CGFloat {
        return navigationController?.navigationBar.frame.height ?? 0
    }
    private var fullHeight: CGFloat {
        return orientationBasedHeight - navHeight
    }

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
        
        let overlayTapGesture = UITapGestureRecognizer(target: self, action:  #selector(self.hideViewWithAnimation))
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
        switch state {
        case .full:
            self.isFullyHidden = false
            self.isFullyShown = true
            panView.frame = CGRect(x: 0, y: navHeight, width: view.frame.width, height: fullHeight)
        case .none:
            self.isFullyHidden = true
            self.isFullyShown = false
            panView.frame = CGRect(x: 0, y: minY, width: view.frame.width, height: fullHeight)
        case .partial:
            self.isFullyHidden = false
            self.isFullyShown = false
            panView.frame = CGRect(x: 0, y: maxY, width: view.frame.width, height: fullHeight)
    
        }
    }

    private func moveView(panGestureRecognizer recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let yVal:CGFloat = translation.y
        let startedYVal = endedTranslationYVal + maxY
        let newYVal = isFullyShown ? navHeight + yVal : startedYVal + yVal
        print("startedYVal \(startedYVal)| yVal \(yVal)| newYVal \(newYVal)| maxY \(maxY)| fullH \(fullHeight)")
        
        // Top
        guard newYVal >= navHeight else {
            endedTranslationYVal = 0
            return
        }
        
        panView.frame = CGRect(x: 0, y: newYVal, width: view.frame.width, height: fullHeight)

        let upYShift: CGFloat = 30 // how much height do we want to let the bottom sheet rise before making it full screen
        
        if recognizer.state == .ended {
            // past middle
            if newYVal > (maxY - 80)*2 {
                endedTranslationYVal = 0
                hideView(shouldAnimate: true)
                return
            } else if newYVal < (maxY - upYShift) {
                endedTranslationYVal = 0
                showFullView()
                return
            }
            
            UIView.animate(withDuration: 0.2, delay: 0.0, options: [.allowUserInteraction], animations: {

                // This means its going down
                if newYVal > (self.maxY - upYShift) {
                    // past middle
                    if newYVal > (self.maxY - 80)*2 {
                        self.moveView(state: .none)
                    } else {
                        self.endedTranslationYVal = 0
                        self.moveView(state: .partial)
                    }

                   // going up
                } else if newYVal < (self.maxY - upYShift) {
                    self.moveView(state: .full)
                }
            }, completion: nil)
        }
    }
    
    @objc func hideView(shouldAnimate: Bool) {
        let closure = {
            self.moveView(state: .none)
            self.isFullyHidden = true
            self.isFullyShown = false
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
            self.moveView(state: .partial)
            self.isFullyHidden = false
            self.isFullyShown = false
            self.overlay.alpha = 1
            self.view.isHidden = false
        })
    }
    
    func showFullView() {
        UIView.animate(withDuration: 0.26, animations: {
            self.moveView(state: .full)
            self.isFullyHidden = false
            self.isFullyShown = true
            self.overlay.alpha = 1
            self.view.isHidden = false
        })
    }

    @objc private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        moveView(panGestureRecognizer: recognizer)
    }
    
    @objc private func hideViewWithAnimation() {
        hideView(shouldAnimate: true)
    }
    
    func applyTheme() {
        if ThemeManager.instance.currentName == .normal {
            panView.backgroundColor = UIColor(rgb: 0xF2F2F7)
        } else {
            panView.backgroundColor = UIColor(rgb: 0x1C1C1E)
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            let orient = UIApplication.shared.statusBarOrientation
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
