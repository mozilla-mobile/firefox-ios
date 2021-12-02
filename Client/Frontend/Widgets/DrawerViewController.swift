// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import SnapKit

struct DrawerViewControllerUX {
    static let HandleAlpha: CGFloat = 0.25
    static let HandleWidth: CGFloat = 35
    static let HandleHeight: CGFloat = 5
    static let HandleMargin: CGFloat = 20
    static let DrawerCornerRadius: CGFloat = 10
    static let DrawerTopStop: CGFloat = 60
    static let DrawerPadWidth: CGFloat = 380
}

public class DrawerView: UIView {
    override public func layoutSubviews() {
        super.layoutSubviews()

        if traitCollection.userInterfaceIdiom == .pad &&
            traitCollection.horizontalSizeClass == .regular {
            // Remove any layer mask to prevent rounded corners for iPad layout.
            layer.mask = nil
        } else {
            // Apply a layer mask to round the top corners of the drawer.
            let shapeLayer = CAShapeLayer()
            let cornerRadii = CGSize(width: DrawerViewControllerUX.DrawerCornerRadius, height: DrawerViewControllerUX.DrawerCornerRadius)
            let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: cornerRadii)
            shapeLayer.frame = bounds
            shapeLayer.path = path.cgPath
            layer.mask = shapeLayer
        }
    }
}

public class DrawerViewController: UIViewController, NotificationThemeable {
    public let childViewController: UIViewController

    public let drawerView = DrawerView()

    fileprivate(set) open var isOpen: Bool = false

    fileprivate var drawerViewTopConstraint: Constraint?
    fileprivate var drawerViewRightConstraint: Constraint?

    fileprivate let backgroundOverlayView = UIView()
    fileprivate let handleView = UIView()

    // Only used in iPad layout.
    fileprivate var xPosition: CGFloat = 0 {
        didSet {
            let maxX = DrawerViewControllerUX.DrawerPadWidth

            if xPosition < maxX - DrawerViewControllerUX.DrawerPadWidth {
                xPosition = maxX - DrawerViewControllerUX.DrawerPadWidth
            } else if xPosition > maxX {
                xPosition = maxX
            }

            backgroundOverlayView.alpha = (1 - (xPosition / maxX)) / 2
            drawerViewRightConstraint?.update(offset: xPosition)
            view.layoutIfNeeded()
        }
    }

    // Only used in non-iPad layout.
    fileprivate var yPosition: CGFloat = DrawerViewControllerUX.DrawerTopStop {
        didSet {
            let maxY = view.frame.maxY

            if yPosition < DrawerViewControllerUX.DrawerTopStop {
                yPosition = DrawerViewControllerUX.DrawerTopStop
            } else if yPosition > maxY {
                yPosition = maxY
            }

            backgroundOverlayView.alpha = (maxY - yPosition) / maxY / 2
            drawerViewTopConstraint?.update(offset: yPosition)
            view.layoutIfNeeded()
        }
    }

    fileprivate var showingPadLayout: Bool {
        return traitCollection.userInterfaceIdiom == .pad &&
            traitCollection.horizontalSizeClass == .regular
    }

    public init(childViewController: UIViewController) {
        self.childViewController = childViewController

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()

        backgroundOverlayView.backgroundColor = .black
        backgroundOverlayView.alpha = 0
        view.addSubview(backgroundOverlayView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didRecognizeTapGesture))
        backgroundOverlayView.addGestureRecognizer(tapGestureRecognizer)

        drawerView.backgroundColor = LegacyThemeManager.instance.currentName == .dark ? UIColor.theme.tableView.rowBackground : UIColor.theme.tableView.headerBackground
        view.addSubview(drawerView)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didRecognizePanGesture))
        panGestureRecognizer.delegate = self
        drawerView.addGestureRecognizer(panGestureRecognizer)

        handleView.backgroundColor = .black
        handleView.alpha = DrawerViewControllerUX.HandleAlpha
        handleView.layer.cornerRadius = DrawerViewControllerUX.HandleHeight / 2
        drawerView.addSubview(handleView)

        addChild(childViewController)
        drawerView.addSubview(childViewController.view)
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        backgroundOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        drawerView.snp.remakeConstraints(constraintsForDrawerView)
        childViewController.view.snp.remakeConstraints(constraintsForChildViewController)
        handleView.snp.remakeConstraints(constraintsForHandleView)

        if showingPadLayout {
            xPosition = DrawerViewControllerUX.DrawerPadWidth
        } else {
            yPosition = view.frame.maxY
        }
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        open()
    }

    public func applyTheme() {
        drawerView.backgroundColor = LegacyThemeManager.instance.currentName == .dark ? UIColor.theme.tableView.rowBackground : UIColor.theme.tableView.headerBackground
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        drawerView.snp.remakeConstraints(constraintsForDrawerView)
        childViewController.view.snp.remakeConstraints(constraintsForChildViewController)
        handleView.snp.remakeConstraints(constraintsForHandleView)
    }

    fileprivate func constraintsForDrawerView(_ make: SnapKit.ConstraintMaker) {
        if showingPadLayout {
            make.width.equalTo(DrawerViewControllerUX.DrawerPadWidth)
            make.height.equalTo(view)
            drawerViewTopConstraint = make.top.equalTo(view).constraint
            drawerViewRightConstraint = make.right.equalTo(xPosition).constraint
        } else {
            make.width.equalTo(view)
            make.height.equalTo(view).offset(-DrawerViewControllerUX.DrawerTopStop)
            drawerViewTopConstraint = make.top.equalTo(yPosition).constraint
            drawerViewRightConstraint = make.right.equalTo(view).constraint
        }
    }

    fileprivate func constraintsForChildViewController(_ make: SnapKit.ConstraintMaker) {
        if showingPadLayout {
            make.height.equalTo(drawerView)
            make.top.equalTo(drawerView)
        } else {
            make.height.equalTo(drawerView).offset(-DrawerViewControllerUX.HandleMargin)
            make.top.equalTo(drawerView).offset(DrawerViewControllerUX.HandleMargin)
        }

        make.width.equalTo(drawerView)
        make.centerX.equalTo(drawerView)
    }

    fileprivate func constraintsForHandleView(_ make: SnapKit.ConstraintMaker) {
        if showingPadLayout {
            make.width.height.equalTo(0)
        } else {
            make.width.equalTo(DrawerViewControllerUX.HandleWidth)
            make.height.equalTo(DrawerViewControllerUX.HandleHeight)
        }

        make.centerX.equalTo(drawerView)
        make.top.equalTo(drawerView).offset((DrawerViewControllerUX.HandleMargin - DrawerViewControllerUX.HandleHeight) / 2)
    }

    @objc fileprivate func didRecognizeTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        guard gestureRecognizer.state == .ended else {
            return
        }

        close()
    }

    @objc fileprivate func didRecognizePanGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        // Drawer is not draggable on iPad layout.
        guard !showingPadLayout else {
            return
        }

        let translation = gestureRecognizer.translation(in: drawerView)
        yPosition += translation.y
        gestureRecognizer.setTranslation(CGPoint.zero, in: drawerView)

        guard gestureRecognizer.state == .ended else {
            return
        }

        let velocity = gestureRecognizer.velocity(in: drawerView).y
        let landingYPosition = yPosition + velocity / 10
        let nextYPosition: CGFloat
        let duration: TimeInterval

        if landingYPosition > view.frame.maxY / 2 {
            nextYPosition = view.frame.maxY
            duration = 0.25
        } else {
            nextYPosition = 0
            duration = 0.25
        }

        UIView.animate(withDuration: duration, animations: {
            self.yPosition = nextYPosition
        }) { _ in
            if nextYPosition > 0 {
                self.view.removeFromSuperview()
                self.removeFromParent()
            }
        }
    }

    public func open() {
        isOpen = true

        UIView.animate(withDuration: 0.25) {
            if self.showingPadLayout {
                self.xPosition = 0
            } else {
                self.yPosition = DrawerViewControllerUX.DrawerTopStop
            }
        }
    }

    public func close(immediately: Bool = false) {
        let duration = immediately ? 0.0 : 0.25
        UIView.animate(withDuration: duration, animations: {
            if self.showingPadLayout {
                self.xPosition = DrawerViewControllerUX.DrawerPadWidth
            } else {
                self.yPosition = self.view.frame.maxY
            }
        }) { _ in
            self.isOpen = false
            self.view.removeFromSuperview()
            self.removeFromParent()
        }
    }
}

extension DrawerViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Don't recognize touches for the pan gesture
        // if they occurred on a `UITableView*` view.
        let description = touch.view?.description ?? ""
        return !description.starts(with: "<UITableView") && !description.starts(with: "<UITextField")
    }
}
