/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

enum BottomSheetState {
    case none
    case partial
    case full
}

protocol BottomSheetDelegate {
    func closeBottomSheet()
}

class BottomSheetViewController: UIViewController {
    var delegate: BottomSheetDelegate?
    var bottomVal: ConstraintMakerEditable?
    let maxInset = 0
    lazy var maxY = view.frame.height - frameHeight
    lazy var minY = view.frame.height
    var endedYVal:CGFloat = 0
    var endedTranslationYVal:CGFloat = 0
    var overlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return view
    }()
    var panView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        return view
    }()
    var isFullyHidden = false
    lazy var frameHeight = view.frame.height/2
    private var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setTitle("Close", for: .normal)
        closeButton.setTitleColor(.blue, for: .normal)
        return closeButton
    }()
    
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
            self.bottomVal = make.bottom.equalTo(self.view.safeArea.bottom)
            make.centerX.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(frameHeight)
        }

        self.panView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(self.panView.snp.top)
            make.left.right.equalTo(self.panView)
            make.height.equalTo(40)
        }
        
        let gesture = UIPanGestureRecognizer.init(target: self, action: #selector(panGesture))
        panView.addGestureRecognizer(gesture)
        panView.translatesAutoresizingMaskIntoConstraints = true

        closeButton.addTarget(self, action: #selector(self.showView), for: .touchUpInside)
        hideView(shouldAnimate: false)
        
        let overlayTapGesture = UITapGestureRecognizer(target: self, action:  #selector(self.hideViewWithAnimation))
        overlay.addGestureRecognizer(overlayTapGesture)
    }
    
    func roundViews() {
        panView.layer.cornerRadius = 10
        view.clipsToBounds = true
        panView.clipsToBounds = true
    }

    private func moveView(state: BottomSheetState) {
        let yPosition = state == .none ? minY : maxY
        panView.frame = CGRect(x: 0, y: yPosition, width: view.frame.width, height: frameHeight)
    }

    private func moveView(panGestureRecognizer recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: view)
        let minY = view.frame.minY
        let yVal:CGFloat = translation.y
        let startedYVal = endedTranslationYVal + maxY
        let newYVal = startedYVal + yVal
        // Debug only
        // print("minY(\(minY) || t.y(\(translation.y)) || maxY(\(maxY)) || endYVal(\(endedTranslationYVal)) || startVal(\(startedYVal)) || newVal(\(newYVal))")
        
        // Top
        guard newYVal >= maxY else {
            endedTranslationYVal = 0
            return
        }
        
        panView.frame = CGRect(x: 0, y: newYVal, width: view.frame.width, height: frameHeight)

        if recognizer.state == .ended {
            
            // past middle
            if newYVal > (maxY - 80)*2 {
                endedTranslationYVal = 0
                hideView(shouldAnimate: true)
                return
            }
            
            endedYVal = maxY + yVal
            endedTranslationYVal = 0
            
            UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
                let state: BottomSheetState = recognizer.velocity(in: self.view).y >= 0 ? .partial : .full
                self.moveView(state: state)
            }, completion: nil)
        }
    }
    
    @objc private func hideViewWithAnimation() {
        hideView(shouldAnimate: true)
    }
    
    @objc func hideView(shouldAnimate: Bool) {
        delegate?.closeBottomSheet()
        let closure = {
            self.moveView(state: .none)
            self.isFullyHidden = true
            self.view.isUserInteractionEnabled = true
            self.overlay.alpha = 0
            self.view.isHidden = true
        }
        guard shouldAnimate else {
            closure()
            return
        }
        self.view.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.4, animations: {
            closure()
        })
    }

    @objc func showView() {
        UIView.animate(withDuration: 0.26, animations: {
            self.moveView(state: .full)
            self.isFullyHidden = false
            self.overlay.alpha = 1
            self.view.isHidden = false
        })
    }

    @objc private func panGesture(_ recognizer: UIPanGestureRecognizer) {
        moveView(panGestureRecognizer: recognizer)
    }
}
