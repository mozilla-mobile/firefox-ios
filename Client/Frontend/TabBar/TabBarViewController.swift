/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

// This is the bounding box of the button. The image is aligned to the top of the box, the text label to the bottom.
private let ButtonSize = CGSize(width: 72, height: 56)

// Color and height of the orange divider
private let DividerColor: UIColor = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
private let DividerHeight: CGFloat = 4.0

// Font name and size used for the button label
private let LabelFontName: String = "FiraSans-Light"
private let LabelFontSize: CGFloat = 13.0

class ToolbarButton: UIButton {
    private var _item: ToolbarItem

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageView = self.imageView {
            imageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            imageView.frame =  CGRect(origin: CGPointMake(imageView.frame.origin.x, 0), size: imageView.frame.size)
        }
        
        if let titleLabel = self.titleLabel {
            titleLabel.frame.size.width = frame.size.width
            titleLabel.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))
            titleLabel.frame = CGRect(origin: CGPointMake(titleLabel.frame.origin.x, super.frame.height - titleLabel.frame.height), size: titleLabel.frame.size)
        }
    }
    
    init(toolbarItem item: ToolbarItem) {
        _item = item

        super.init(frame: CGRect(x: 0, y: 0, width: ButtonSize.width, height: ButtonSize.height))
        titleLabel?.font = UIFont(name: LabelFontName, size: LabelFontSize)
        titleLabel?.textAlignment = NSTextAlignment.Center
        titleLabel?.sizeToFit()
        updateForItem()
    }

    var item: ToolbarItem {
        get {
            return self._item
        }

        set {
            self._item = newValue
            updateForItem()
        }
    }

    private func updateForItem() {
        setImage(UIImage(named: "nav-\(_item.imageName)-off.png"), forState: UIControlState.Normal)
        setImage(UIImage(named: "nav-\(_item.imageName)-on.png"), forState: UIControlState.Selected)
        setTitle(_item.title, forState: UIControlState.Normal)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ToolbarContainerView: UIView {
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, DividerColor.CGColor)
        CGContextFillRect(context, CGRect(x: 0, y: frame.height-DividerHeight, width: frame.width, height: DividerHeight))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var origin = CGPoint(x: (frame.width - CGFloat(countElements(subviews)) * ButtonSize.width) / 2.0,
            y: (frame.height - ButtonSize.height) / 2.0)
        origin.y += 15 - DividerHeight
        
        for view in subviews as [UIView] {
            view.frame = CGRect(origin: origin, size: view.frame.size)
            origin.x += ButtonSize.width
        }
    }
}

class TabBarViewController: UIViewController {
    @IBOutlet weak var buttonContainerView: ToolbarContainerView!

    let TransitionDuration = 0.25
    var buttons: [ToolbarButton] = []
    var account: Account!
    var notificationToken: NSObjectProtocol!
    var panels: [ToolbarItem]!

    var onScreenFrame: CGRect {
        var frame = view.frame
        frame.size.height -= buttonContainerView.frame.height
        frame.origin.y += buttonContainerView.frame.height
        return frame
    }

    var offScreenFrame: CGRect {
        var frame = self.onScreenFrame
        frame.origin.y += frame.height
        return frame
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(notificationToken)
    }
    
    private var _selectedButtonIndex: Int = 0
    var selectedButtonIndex: Int {
        get {
            return _selectedButtonIndex
        }

        set (newButtonIndex) {
            let currentButton = buttons[_selectedButtonIndex]
            currentButton.selected = false

            let newButton = buttons[newButtonIndex]
            newButton.selected = true
            
            hideCurrentViewController() {
                var vc = self.panels[newButtonIndex].generator(account: self.account)
                self.showViewController(vc) {
                    // Do Nothing
                }
            }

            _selectedButtonIndex = newButtonIndex
        }
    }

    private func hideCurrentViewController(callback: () -> Void) {
        UIApplication.sharedApplication().beginIgnoringInteractionEvents()

        if (childViewControllers.count > 0) {
            if var vc = childViewControllers[0] as? UIViewController {
                transitionFromViewController(vc, toViewController: vc, duration: self.TransitionDuration, options: UIViewAnimationOptions.allZeros, animations: { () -> Void in
                        // Slide the visible controller down
                        vc.view.frame = self.offScreenFrame
                    }, completion: { (Bool) -> Void in
                        vc.view.removeFromSuperview()
                        vc.removeFromParentViewController()
                        callback()
                    })
            }
        } else {
            callback()
        }
    }
    
    private func showViewController(vc: UIViewController, callback: () -> Void) {
        self.view.addSubview(vc.view)
        vc.view.frame = offScreenFrame
        addChildViewController(vc)
        
        UIView.animateWithDuration(self.TransitionDuration, animations: { () -> Void in
            vc.view.frame = self.onScreenFrame
        }, completion: { (Bool) -> Void in
            UIApplication.sharedApplication().endIgnoringInteractionEvents()
            callback()
        })
    }
    
    func tappedButton(sender: UIButton!) {
        for (index, button) in enumerate(buttons) {
            if (button == sender) {
                selectedButtonIndex = index
                break
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    private func updateButtons() {
        for index in 0...panels.count-1 {
            let item = panels[index]
            // If we have a button, we'll just reuse it
            if (index < buttons.count) {
                let button = buttons[index]
                // TODO: Write a better equality check here.
                if (item.title == button.item.title) {
                    continue
                }

                button.item = item
            } else {
                // Otherwise create one
                let toolbarButton = ToolbarButton(toolbarItem: item)
                buttonContainerView.addSubview(toolbarButton)
                toolbarButton.addTarget(self, action: "tappedButton:", forControlEvents: UIControlEvents.TouchUpInside)
                buttons.append(toolbarButton)
            }
        }

        // Now remove any extra buttons we find
        // Note, since we modify index in the loop, we have to use the old for-loop syntax here.
        // XXX - There's probably a better way to do this
        for (var index = panels.count; index < buttons.count; index++) {
            let button = buttons[index]
            button.removeFromSuperview()
            buttons.removeAtIndex(index)
            index--
        }
    }
    
    override func viewDidLoad() {
        self.panels = Panels(account: self.account).enabledItems
        updateButtons()
        selectedButtonIndex = 0
    }
    
    override func viewWillAppear(animated: Bool) {
        notificationToken = NSNotificationCenter.defaultCenter().addObserverForName(PanelsNotificationName, object: nil, queue: nil) { notif in
            self.panels = Panels(account: self.account).enabledItems
            self.updateButtons()
        }
    }
}
