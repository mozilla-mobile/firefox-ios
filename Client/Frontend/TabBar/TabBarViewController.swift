// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit


// This is the bounding box of the button. The image is aligned to the top of the box, the text label to the bottom.
let BUTTON_SIZE = CGSize(width: 72, height: 56)

// Color and height of the orange divider
let DIVIDER_COLOR: UIColor = UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0, alpha: 1.0)
let DIVIDER_HEIGHT: CGFloat = 4.0

// Font name and size used for the button label
let LABEL_FONT_NAME: String = "FiraSans-Light"
let LABEL_FONT_SIZE: CGFloat = 13.0


class ToolbarButton: UIButton
{
    var _item: ToolbarItem?;

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
        super.init(frame: CGRect(x: 0, y: 0, width: BUTTON_SIZE.width, height: BUTTON_SIZE.height))
        titleLabel?.font = UIFont(name: LABEL_FONT_NAME, size: LABEL_FONT_SIZE)
        titleLabel?.textAlignment = NSTextAlignment.Center
        titleLabel?.sizeToFit()

        self.item = item
    }

    var item: ToolbarItem? {
        get {
            return self._item;
        }

        set {
            self._item = newValue;
            if var item = newValue {
                setImage(UIImage(named: "nav-\(item.imageName)-off.png"), forState: UIControlState.Normal)
                setImage(UIImage(named: "nav-\(item.imageName)-on.png"), forState: UIControlState.Selected)
                setTitle(item.title, forState: UIControlState.Normal)
            } else {
                setImage(nil, forState: UIControlState.Normal)
                setImage(nil, forState: UIControlState.Selected)
                setTitle("", forState: UIControlState.Normal)
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ToolbarContainerView: UIView
{
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        let context = UIGraphicsGetCurrentContext()
        CGContextSetFillColorWithColor(context, DIVIDER_COLOR.CGColor)
        CGContextFillRect(context, CGRect(x: 0, y: frame.height-DIVIDER_HEIGHT, width: frame.width, height: DIVIDER_HEIGHT))
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        var origin = CGPoint(x: (frame.width - CGFloat(countElements(subviews)) * BUTTON_SIZE.width) / 2.0,
            y: (frame.height - BUTTON_SIZE.height) / 2.0)
        origin.y += 15 - DIVIDER_HEIGHT
        
        for view in subviews as [UIView] {
            view.frame = CGRect(origin: origin, size: view.frame.size)
            origin.x += BUTTON_SIZE.width
        }
    }
}


class TabBarViewController: UIViewController
{
    var buttons: [ToolbarButton] = []
    var panels : [ToolbarItem];
    var _selectedButtonIndex: Int = -1
    var accountManager: AccountManager!
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, accountManager: AccountManager) {
        self.accountManager = accountManager;
        panels = Panels(accountManager: self.accountManager).enabledItems;
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);

        NSNotificationCenter.defaultCenter().addObserverForName(PanelsNotificationName, object: nil, queue: nil) { notif in
            self.panels = Panels(accountManager: accountManager).enabledItems;
            self.updateButtons();
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var selectedButtonIndex: Int {
        get {
            return _selectedButtonIndex
        }

        set (newButtonIndex) {
            if (_selectedButtonIndex != -1) {
                let currentButton = buttons[_selectedButtonIndex]
                currentButton.selected = false
            }

            let newButton = buttons[newButtonIndex]
            newButton.selected = true
            
            // Update the active view controller
            if let buttonContainerView = view.viewWithTag(1) {
                var onScreenFrame = view.frame
                onScreenFrame.size.height -= buttonContainerView.frame.height
                onScreenFrame.origin.y += buttonContainerView.frame.height
                
                var offScreenFrame = onScreenFrame
                offScreenFrame.origin.y += offScreenFrame.height

                if (_selectedButtonIndex == -1) {
                    var visibleViewController : UIViewController?;
                    if (childViewControllers.count > 0) {
                        visibleViewController = childViewControllers[0] as? UIViewController
                    } else {
                        visibleViewController = panels[0].generator(accountManager: accountManager)
                    }

                    if var vc = visibleViewController {
                        vc.view.frame = onScreenFrame
                        addChildViewController(vc)
                        view.addSubview(vc.view)
                        vc.didMoveToParentViewController(self)
                    }
                } else {
                    var visibleViewController = childViewControllers[0] as UIViewController;
                    var newViewController = panels[newButtonIndex].generator(accountManager: accountManager)
                    
                    visibleViewController.willMoveToParentViewController(nil)
                    newViewController.view.frame = offScreenFrame
                    addChildViewController(newViewController)
                    
                    UIApplication.sharedApplication().beginIgnoringInteractionEvents()
                    
                    transitionFromViewController(visibleViewController, toViewController: newViewController, duration: 0.25, options: UIViewAnimationOptions.allZeros, animations: { () -> Void in
                        // Slide the visible controller down
                        visibleViewController.view.frame = offScreenFrame
                    }, completion: { (Bool) -> Void in
                        visibleViewController.view.removeFromSuperview()
                        self.view.addSubview(newViewController.view)
                        newViewController.view.frame = offScreenFrame
                        
                        UIView.animateWithDuration(0.25, animations: { () -> Void in
                            newViewController.view.frame = onScreenFrame
                        }, completion: { (Bool) -> Void in
                            UIApplication.sharedApplication().endIgnoringInteractionEvents()
                        })
                    })
                }
            }
            
            _selectedButtonIndex = newButtonIndex
        }
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
        for (var index = 0; index < panels.count; index++) {
            let item = panels[index];
            // If we have a button, we'll just reuse it
            if (index < buttons.count) {
                let button = buttons[index];
                // TODO: Write a better equality check here.
                if (item.title == button.item!.title) {
                    continue;
                }

                button.item = item;
            } else {
                // Otherwise create one
                if let buttonContainerView = view.viewWithTag(1) {
                    let toolbarButton = ToolbarButton(toolbarItem: item)
                    buttonContainerView.addSubview(toolbarButton)
                    toolbarButton.addTarget(self, action: "tappedButton:", forControlEvents: UIControlEvents.TouchUpInside)
                    buttons.append(toolbarButton)
                }
            }
        }

        // Now remove any extra buttons we find
        for (var index = panels.count; index < buttons.count; index++) {
            let button = buttons[index]
            button.removeFromSuperview()
            buttons.removeAtIndex(index);
            index--;
        }
    }
    
    override func viewDidLoad() {
        if let buttonContainerView = view.viewWithTag(1) {
            updateButtons();
            selectedButtonIndex = 0
        }
    }
}
