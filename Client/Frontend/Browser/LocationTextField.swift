/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// This code is loosely based on https://github.com/Antol/APAutocompleteTextField

import UIKit

struct LocationSuggestion {
    var location: String
    var url: NSURL?
}

protocol LocationTextFieldDelegate {
    /// Fired when the text field becomes active
    func locationTextFieldDidBeginEditing(locationTextField: LocationTextField)
    /// Fired with the text field has been submitted
    func locationTextFieldDidReturn(locationTextField: LocationTextField, url: NSURL)
    /// Fired when the text field is asking for a completion suggestion. Return nil if no completion is available.
    func locationTextField(locationTextField: LocationTextField, suggestionForPartialLocation partialLocation: String) -> LocationSuggestion?
}

class LocationTextField: UITextField, UITextFieldDelegate {
    var locationTextFieldDelegate: LocationTextFieldDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.delegate = self
    }
    
    override func textRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.textRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect {
        let rect = super.editingRectForBounds(bounds)
        return rect.rectByInsetting(dx: 5, dy: 5)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        locationTextFieldDelegate?.locationTextFieldDidBeginEditing(self)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        // If we have an completion suggestion then we use that URL
        if let completionURL = self.completionURL {
            dispatch_async(dispatch_get_main_queue()) {
                if let locationTextFieldDelegate = self.locationTextFieldDelegate {
                    locationTextFieldDelegate.locationTextFieldDidReturn(self, url: completionURL)
                }
            }
            return false
        }
        
        // Otherwise take the URL from the text field. We parse it and if a scheme is missing we
        // add http:// and try again. We can probably do some smarter things here but I think
        // this is a decent start that at least lets people skip typing the protocol.

        let urlString = textField.text
        
        var url = NSURL(string: urlString)
        if url == nil || url?.scheme == nil {
            url = NSURL(string: "http://" + urlString)
            if url == nil {
                println("Error parsing URL: " + urlString)
                return false
            }
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            if let locationTextFieldDelegate = self.locationTextFieldDelegate {
                locationTextFieldDelegate.locationTextFieldDidReturn(self, url: url!)
            }
        }
        
        return false
    }
    
    // MARK: Completion handling
    
    private var completionActive = false
    private var completionColor: UIColor = UIColor(red: 0.8, green: 0.87, blue: 0.93, alpha: 1.0)
    private var completionPrefixLength = 0
    private var completionURL: NSURL?
    
    private func applyCompletion() {
        if completionActive {
            self.attributedText = NSAttributedString(string: self.text)
            completionActive = false
        }
    }
    
    private func removeCompletion() {
        if completionActive {
            var notCompletedString = self.text
            if countElements(notCompletedString) > completionPrefixLength {
                notCompletedString = self.text.substringToIndex(advance(self.text.startIndex, completionPrefixLength))
            }
            self.attributedText = NSAttributedString(string: notCompletedString)
            completionActive = false
        }
    }

    private func completeString() {
        var completedAndMarkedString: NSMutableAttributedString?
        
        if let endingString = endingString() {
            let completedString = self.text + endingString
            
            completedAndMarkedString = NSMutableAttributedString(string: completedString)
            completedAndMarkedString?.addAttribute(NSBackgroundColorAttributeName, value: completionColor, range: NSMakeRange(completionPrefixLength, countElements(endingString)))
        }
        
        if completedAndMarkedString != nil {
            self.attributedText = completedAndMarkedString
            completionActive = true
        }
    }
    
    private func endingString() -> String? {
        if countElements(self.text) != 0 {
            if let suggestion = locationTextFieldDelegate?.locationTextField(self, suggestionForPartialLocation: self.text) {
                let location = suggestion.location
                self.completionURL = suggestion.url
                return location.substringFromIndex(advance(location.startIndex, countElements(self.text!)))
            } else {
                self.completionURL = nil
            }
        }
        return nil
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if completionActive {
            // Special range that is fired in case of deletion
            if range.length == 1 && countElements(string) == 0 {
                removeCompletion()
                return false
            }
        }
        return true
    }

    // MARK: UIKeyInput Overrides
    
    override func insertText(text: String) {
        removeCompletion()
        super.insertText(text)
        completionPrefixLength = countElements(self.text)
        completeString()
    }
    
    override func caretRectForPosition(position: UITextPosition!) -> CGRect {
        if !completionActive {
            return super.caretRectForPosition(position)
        } else {
            return CGRectZero
        }
    }
    
    override func resignFirstResponder() -> Bool {
        applyCompletion()
        return super.resignFirstResponder()
    }
    
    // MARK: UIResponder Overrides
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        if !completionActive {
            super.touchesBegan(touches, withEvent: event)
        }
    }
    
    override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
        if !completionActive {
            super.touchesMoved(touches, withEvent: event)
        }
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        if !completionActive {
            super.touchesBegan(touches, withEvent: event)
        } else {
            applyCompletion()
            self.selectedTextRange = textRangeFromPosition(self.positionFromPosition(self.beginningOfDocument, offset: completionPrefixLength), toPosition: self.endOfDocument)
        }
    }
}
