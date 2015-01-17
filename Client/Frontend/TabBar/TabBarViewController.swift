/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Snappy
import UIKit

// This is the bounding box of the button. The image is aligned to the top of the box, the text label to the bottom.
private let ButtonSize = CGSize(width: 72, height: 56)

// Color and height of the orange divider
private let DividerColor: UIColor = UIColor(red: 255.0 / 255, green: 149.0 / 255, blue: 0.0 / 255, alpha: 1)
private let DividerHeight: CGFloat = 4.0

// Font name and size used for the button label
private let LabelFontName: String = "FiraSans-Light"
private let LabelFontSize: CGFloat = 13.0

private let BackgroundColor = UIColor(red: 57.0 / 255, green: 57.0 / 255, blue: 57.0 / 255, alpha: 1)
private let TransitionDuration = 0.25

protocol TabBarViewControllerDelegate: class {
    func didEnterURL(url: NSURL)
}

// A protocol to support clicking on rows in the view controller
// This needs to be accessible to objc for UIViewControllers to implement it
@objc
protocol UrlViewController: class {
    var delegate: UrlViewControllerDelegate? { get set }
}

class TabBarViewController: UIViewController, UITextFieldDelegate, UrlViewControllerDelegate {
    var profile: Profile!
    var notificationToken: NSObjectProtocol!
    var panels: [ToolbarItem]!
    var url: NSURL?
    weak var delegate: TabBarViewControllerDelegate?

    private var buttonContainerView: ToolbarContainerView!
    private var controllerContainerView: UIView!
    private var toolbarTextField: UITextField!
    private var cancelButton: UIButton!
    private var buttons: [ToolbarButton] = []
    private var searchController: SearchViewController?
    private let uriFixup = URIFixup()
    
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
            
            hideCurrentViewController()
            var vc = self.panels[newButtonIndex].generator(profile: self.profile)
            self.showViewController(vc)
            if let v = vc as? UrlViewController {
                v.delegate = self
            }

            _selectedButtonIndex = newButtonIndex
        }
    }

    private func hideCurrentViewController() {
        if let vc = childViewControllers.first? as? UIViewController {
            vc.view.removeFromSuperview()
            vc.removeFromParentViewController()
            toolbarTextField.resignFirstResponder()
        }
    }
    
    private func showViewController(vc: UIViewController) {
        controllerContainerView.addSubview(vc.view)
        vc.view.snp_makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        addChildViewController(vc)
    }

    private func showSearchController() {
        if searchController != nil {
            return
        }

        searchController = SearchViewController()
        searchController!.searchEngines = profile.searchEngines
        searchController!.delegate = self

        view.addSubview(searchController!.view)
        searchController!.view.snp_makeConstraints { make in
            make.top.equalTo(self.toolbarTextField.snp_bottom).offset(10)
            make.left.right.bottom.equalTo(self.view)
        }

        addChildViewController(searchController!)
    }

    private func hideSearchController() {
        if let searchController = searchController {
            searchController.view.removeFromSuperview()
            searchController.removeFromParentViewController()
            self.searchController = nil
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
        view.backgroundColor = BackgroundColor

        buttonContainerView = ToolbarContainerView()
        buttonContainerView.backgroundColor = BackgroundColor
        view.addSubview(buttonContainerView)

        controllerContainerView = UIView()
        view.addSubview(controllerContainerView)

        toolbarTextField = ToolbarTextField()
        toolbarTextField.keyboardType = UIKeyboardType.WebSearch
        toolbarTextField.autocorrectionType = UITextAutocorrectionType.No
        toolbarTextField.autocapitalizationType = UITextAutocapitalizationType.None
        toolbarTextField.returnKeyType = UIReturnKeyType.Go
        toolbarTextField.clearButtonMode = UITextFieldViewMode.WhileEditing
        toolbarTextField.layer.backgroundColor = UIColor.whiteColor().CGColor
        toolbarTextField.layer.cornerRadius = 8
        toolbarTextField.delegate = self
        toolbarTextField.text = url?.absoluteString
        toolbarTextField.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        toolbarTextField.becomeFirstResponder()
        view.addSubview(toolbarTextField)

        cancelButton = UIButton()
        cancelButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        cancelButton.setTitle("Cancel", forState: UIControlState.Normal)
        cancelButton.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        cancelButton.addTarget(self, action: "SELdidClickCancel", forControlEvents: UIControlEvents.TouchUpInside)
        view.addSubview(cancelButton)

        // Since the cancel button is next to toolbarTextField, and toolbarTextField can expand to the full width,
        // give the cancel button a higher compression resistance priority to prevent it from being hidden.g
        cancelButton.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Horizontal)

        toolbarTextField.snp_makeConstraints { make in
            // 28.5 matches the position of the URL bar in BrowserViewController. If we want this to be
            // less fragile, we could pass the offset as a parameter to this view controller.
            make.top.equalTo(self.view).offset(28.5)
            make.left.equalTo(self.view).offset(8)
        }

        cancelButton.snp_makeConstraints { make in
            make.left.equalTo(self.toolbarTextField.snp_right).offset(8)
            make.centerY.equalTo(self.toolbarTextField)
            make.right.equalTo(self.view).offset(-8)
        }

        buttonContainerView.snp_makeConstraints { make in
            make.top.equalTo(self.toolbarTextField.snp_bottom)
            make.left.right.equalTo(self.view)
            make.height.equalTo(90)
        }

        controllerContainerView.snp_makeConstraints { make in
            make.top.equalTo(self.buttonContainerView.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }

        self.panels = Panels(profile: self.profile).enabledItems
        updateButtons()
        selectedButtonIndex = 0
    }

    override func viewWillAppear(animated: Bool) {
        notificationToken = NSNotificationCenter.defaultCenter().addObserverForName(PanelsNotificationName, object: nil, queue: nil) { [unowned self] notif in
            self.panels = Panels(profile: self.profile).enabledItems
            self.updateButtons()
        }
    }

    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        let text = textField.text as NSString
        let searchText = text.stringByReplacingCharactersInRange(range, withString: string)
        if searchText.isEmpty {
            hideSearchController()
        } else {
            showSearchController()
            searchController!.searchQuery = searchText
        }

        return true
    }

    func textFieldDidBeginEditing(textField: UITextField) {
        textField.selectAll(nil)
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let text = toolbarTextField.text
        var url = uriFixup.getURL(text)

        // If we can't make a valid URL, do a search query.
        if url == nil {
            url = profile.searchEngines.defaultEngine.urlForQuery(text)
        }

        // If we still don't have a valid URL, something is broken. Give up.
        if url == nil {
            println("Error handling URL entry: " + text)
            return false
        }

        delegate?.didEnterURL(url!)
        dismissViewControllerAnimated(true, completion: nil)
        return false
    }

    func textFieldShouldClear(textField: UITextField) -> Bool {
        hideSearchController()
        return true
    }

    func didClickUrl(url: NSURL) {
        delegate?.didEnterURL(url)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func SELdidClickCancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

private class ToolbarButton: UIButton {
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

private class ToolbarContainerView: UIView {
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
        origin.y += 5 - DividerHeight

        for view in subviews as [UIView] {
            view.frame = CGRect(origin: origin, size: view.frame.size)
            origin.x += ButtonSize.width
        }
    }
}

private class ToolbarTextField: UITextField {
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.textRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }

    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.editingRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }
}
