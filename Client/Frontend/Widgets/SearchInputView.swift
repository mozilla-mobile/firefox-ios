// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import SnapKit

private struct SearchInputViewUX {

    static let horizontalSpacing: CGFloat = 16
    static let titleFont = UIFont.systemFont(ofSize: 16)
    static let borderLineWidth: CGFloat = 0.5
    static let closeButtonSize: CGFloat = 36
}

@objc protocol SearchInputViewDelegate: AnyObject {

    func searchInputView(_ searchView: SearchInputView, didChangeTextTo text: String)

    func searchInputViewBeganEditing(_ searchView: SearchInputView)

    func searchInputViewFinishedEditing(_ searchView: SearchInputView)
}

class SearchInputView: UIView, NotificationThemeable {

    weak var delegate: SearchInputViewDelegate?

    var showBottomBorder: Bool = true {
        didSet {
            bottomBorder.isHidden = !showBottomBorder
        }
    }

    lazy var inputField: UITextField = {
        let textField = UITextField()
        textField.delegate = self
        textField.addTarget(self, action: #selector(inputTextDidChange), for: .editingChanged)
        textField.accessibilityLabel = .SearchInputAccessibilityLabel
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        return textField
    }()

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = .SearchInputTitle
        label.font = SearchInputViewUX.titleFont
        return label
    }()

    lazy var searchIcon: UIImageView = {
        return UIImageView(image: UIImage(named: "quickSearch"))
    }()

    fileprivate lazy var closeButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(tappedClose), for: .touchUpInside)
        button.setImage(UIImage(named: "clear"), for: [])
        button.accessibilityLabel = .SearchInputClearAccessibilityLabel
        return button
    }()

    fileprivate var centerContainer = UIView()

    fileprivate lazy var bottomBorder: UIView = {
        let border = UIView()
        return border
    }()

    fileprivate lazy var overlay: UIView = {
        let view = UIView()
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedSearch)))
        view.isAccessibilityElement = true
        view.accessibilityLabel = .SearchInputEnterSearchMode
        return view
    }()

    fileprivate(set) var isEditing = false {
        didSet {
            if isEditing {
                overlay.isHidden = true
                inputField.isHidden = false
                inputField.accessibilityElementsHidden = false
                closeButton.isHidden = false
                closeButton.accessibilityElementsHidden = false
            } else {
                overlay.isHidden = false
                inputField.isHidden = true
                inputField.accessibilityElementsHidden = true
                closeButton.isHidden = true
                closeButton.accessibilityElementsHidden = true
            }
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        isUserInteractionEnabled = true

        addSubview(inputField)
        addSubview(closeButton)

        centerContainer.addSubview(searchIcon)
        centerContainer.addSubview(titleLabel)
        overlay.addSubview(centerContainer)
        addSubview(overlay)
        addSubview(bottomBorder)

        setupConstraints()

        setEditing(false)

        applyTheme()
    }

    fileprivate func setupConstraints() {
        centerContainer.snp.makeConstraints { make in
            make.center.equalTo(overlay)
        }

        overlay.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        searchIcon.snp.makeConstraints { make in
            make.right.equalTo(titleLabel.snp.left).offset(-SearchInputViewUX.horizontalSpacing)
            make.centerY.equalTo(centerContainer)
        }

        titleLabel.snp.makeConstraints { make in
            make.center.equalTo(centerContainer)
        }

        inputField.snp.makeConstraints { make in
            make.left.equalTo(self).offset(SearchInputViewUX.horizontalSpacing)
            make.centerY.equalTo(self)
            make.right.equalTo(closeButton.snp.left).offset(-SearchInputViewUX.horizontalSpacing)
        }

        closeButton.snp.makeConstraints { make in
            make.right.equalTo(self).offset(-SearchInputViewUX.horizontalSpacing)
            make.centerY.equalTo(self)
            make.size.equalTo(SearchInputViewUX.closeButtonSize)
        }

        bottomBorder.snp.makeConstraints { make in
            make.left.right.bottom.equalTo(self)
            make.height.equalTo(SearchInputViewUX.borderLineWidth)
        }
    }

    // didSet callbacks don't trigger when a property is being set in the init() call
    // but calling a method that does works fine.
    fileprivate func setEditing(_ editing: Bool) {
        isEditing = editing
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme() {
        backgroundColor = UIColor.theme.tableView.rowBackground
        overlay.backgroundColor = backgroundColor
        titleLabel.textColor = UIColor.theme.tableView.rowText
        inputField.textColor = titleLabel.textColor
    }
}

// MARK: - Selectors
extension SearchInputView {

    @objc func tappedSearch() {
        isEditing = true
        inputField.becomeFirstResponder()
        delegate?.searchInputViewBeganEditing(self)
    }

    @objc func tappedClose() {
        isEditing = false
        delegate?.searchInputViewFinishedEditing(self)
        inputField.text = nil
        inputField.resignFirstResponder()
    }

    @objc func inputTextDidChange(_ textField: UITextField) {
        delegate?.searchInputView(self, didChangeTextTo: textField.text ?? "")
    }
}

// MARK: - UITextFieldDelegate
extension SearchInputView: UITextFieldDelegate {

    func textFieldDidEndEditing(_ textField: UITextField) {
        // If there is no text, go back to showing the title view
        if textField.text?.isEmpty ?? true {
            isEditing = false
            delegate?.searchInputViewFinishedEditing(self)
        }
    }
}
