// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit


// This is the bounding box of the button. The image is aligned to the top of the box, the text label to the bottom.
let BUTTON_SIZE = CGSize(width: 72, height: 56)

// Color and height of the orange divider
let DIVIDER_COLOR: UIColor = UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0, alpha: 1.0)
let DIVIDER_HEIGHT: CGFloat = 4.0

// Font name and size used for the button label
let LABEL_FONT_NAME: String = "FiraSans-Light"
let LABEL_FONT_SIZE: CGFloat = 13.0


struct ToolbarItem
{
    var title: String
    var imageName: String
    var viewController: UIViewController
}


extension ToolbarItem
{
    static let Tabs = ToolbarItem(title: "Tabs", imageName: "tabs", viewController: TabsViewController(nibName: nil, bundle: nil))
    static let Bookmarks = ToolbarItem(title: "Bookmarks", imageName: "bookmarks", viewController: BookmarksViewController(nibName: nil, bundle: nil))
    static let History = ToolbarItem(title: "History", imageName: "history", viewController: HistoryViewController(nibName: "HistoryViewController", bundle: nil))
    static let Reader = ToolbarItem(title: "Reader", imageName: "reader", viewController: SiteTableViewController(nibName: nil, bundle: nil))
    static let Settings = ToolbarItem(title: "Settings", imageName: "settings", viewController: SettingsViewController(nibName: "SettingsViewController", bundle: nil))
}


class ToolbarButton: UIButton
{
    var item: ToolbarItem?

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
        self.item = item
        
        setImage(UIImage(named: "nav-\(item.imageName)-off.png"), forState: UIControlState.Normal)
        setImage(UIImage(named: "nav-\(item.imageName)-on.png"), forState: UIControlState.Selected)
        
        titleLabel?.font = UIFont(name: LABEL_FONT_NAME, size: LABEL_FONT_SIZE)
        titleLabel?.textAlignment = NSTextAlignment.Center
        titleLabel?.sizeToFit()
        titleLabel?.textColor = UIColor.whiteColor()
        
        setTitle(item.title, forState: UIControlState.Normal)
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
    var items: [ToolbarItem] = [ToolbarItem.Tabs, ToolbarItem.Bookmarks, ToolbarItem.History, ToolbarItem.Reader, ToolbarItem.Settings]
    var buttons: [ToolbarButton] = []
    
    var _selectedButtonIndex: Int = -1
    
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
                    var visibleViewController = items[newButtonIndex].viewController
                    visibleViewController.view.frame = onScreenFrame
                    addChildViewController(visibleViewController)
                    view.addSubview(visibleViewController.view)
                    visibleViewController.didMoveToParentViewController(self)
                } else {
                    var visibleViewController = items[_selectedButtonIndex].viewController
                    var newViewController = items[newButtonIndex].viewController
                    
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
    
    override func viewDidLoad() {
        if let buttonContainerView = view.viewWithTag(1) {
            for (index, item) in enumerate(items) {
                var toolbarButton = ToolbarButton(toolbarItem: item)
                buttonContainerView.addSubview(toolbarButton)
                toolbarButton.addTarget(self, action: "tappedButton:", forControlEvents: UIControlEvents.TouchUpInside)
                buttons.append(toolbarButton)
            }

            selectedButtonIndex = 0
        }
    }
}
