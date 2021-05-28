//
//  SpinnerAlertView.swift
//  CredentialProvider
//
//  Created by razvan.litianu on 28.05.2021.
//  Copyright © 2021 Mozilla. All rights reserved.
//

import UIKit

protocol SpinnerAlertView {
    var spinnerAlertView: SpinnerAlert? { get }
    func displaySpinner(message: String)
    func hideSpinner(completionMessage: String)
}

extension UIViewController: SpinnerAlertView {
    var spinnerAlertView: SpinnerAlert? {
        return view.subviews.first { $0 is SpinnerAlert } as? SpinnerAlert
    }
    
    
    func displaySpinner(message: String) {
        guard let spinnerAlertView = Bundle.main.loadNibNamed("SpinnerAlert", owner: self)?.first as? SpinnerAlert else {
            return
        }
        spinnerAlertView.text.text = message
        styleAndCenterAlert(spinnerAlertView)
        
        view.addSubview(spinnerAlertView)
        
        spinnerAlertView.activityIndicatorView.startAnimating()
        animateAlertIn(spinnerAlertView)
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: message)
    }
    
    func hideSpinner(completionMessage: String) {
        spinnerAlertView?.text.text = completionMessage
        UIAccessibility.post(notification: UIAccessibility.Notification.announcement, argument: completionMessage)
        spinnerAlertView.map { animateAlertOut($0) }
    }
}

extension UIViewController {
    fileprivate func styleAndCenterAlert(_ view: UIView) {
        view.layer.cornerRadius = 10.0
        view.clipsToBounds = true
        view.center = CGPoint(
            x: self.view.bounds.width * 0.5,
            y: self.view.bounds.height * Constant.number.displayAlertYPercentage
        )
        view.setNeedsLayout()
        view.layoutIfNeeded()
        view.alpha = 0.0
    }
    
    fileprivate func animateAlertIn(_ view: UIView, completion: @escaping ((Bool) -> Void) = { _ in }) {
        UIView.animate(
            withDuration: Constant.number.displayAlertFade,
            animations: {
                view.alpha = Constant.number.displayAlertOpacity
            }, completion: completion)
    }
    
    fileprivate func animateAlertOut(_ view: UIView, delay: TimeInterval = 0.0) {
        UIView.animate(
            withDuration: Constant.number.displayAlertFade,
            delay: delay,
            animations: {
                view.alpha = 0.0
            },
            completion: { _ in
                view.removeFromSuperview()
            })
    }
}

public let isRunningTest = NSClassFromString("XCTestCase") != nil


enum Constant {
    enum number {
        static let displayStatusAlertLength = isRunningTest ? TimeInterval(0.0) : TimeInterval(1.5)
        static let displayAlertFade = isRunningTest ? TimeInterval(0.0) : TimeInterval(0.3)
        static let displayAlertOpacity: CGFloat = 0.75
        static let displayAlertYPercentage: CGFloat = 0.4
        static let fxaButtonTopSpaceFirstLogin: CGFloat = 88.0
        static let fxaButtonTopSpaceUnlock: CGFloat = 40.0
        static let copyExpireTimeSecs = 60
        static let minimumSpinnerHUDTime = isRunningTest ? TimeInterval(0.0) : TimeInterval(1.0)
    }
}
