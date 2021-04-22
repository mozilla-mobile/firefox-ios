/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

class LibraryNativeViewController: UIViewController, Themeable {
    // Public constants
    let viewModel = LibraryPanelViewModel()
    static let theme = BuiltinThemeName(rawValue: ThemeManager.instance.current.name) ?? .normal
    
    // Private vars
    private var fxTextThemeColour: UIColor {
        // For dark theme we want to show light colours and for light we want to show dark colours
        return LibraryNativeViewController.theme == .dark ? .white : .black
    }
    private var fxBackgroundThemeColour: UIColor {
        return LibraryNativeViewController.theme == .dark ? .black : .white
    }
    
    lazy var librarySegmentControl: UISegmentedControl = {
        var librarySegmentControl: UISegmentedControl
        librarySegmentControl = UISegmentedControl(items: [UIImage(named: "library-bookmark")!,
                                                           UIImage(named: "library-history")!,
                                                           UIImage(named: "library-downloads")!,
                                                           UIImage(named: "library-readinglist")!])
        librarySegmentControl.accessibilityIdentifier = "librarySegmentControl"
        librarySegmentControl.selectedSegmentIndex = 1
        librarySegmentControl.addTarget(self, action: #selector(panelChanged), for: .valueChanged)
        return librarySegmentControl
    }()
    
    // Toolbars
    lazy var navigationToolbar: UIToolbar = {
        let toolbar = UIToolbar()
        toolbar.delegate = self
        toolbar.setItems([UIBarButtonItem(customView: librarySegmentControl)], animated: false)
        return toolbar
    }()
    
    fileprivate lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = DynamicFontHelper.defaultHelper.DefaultStandardFontBold
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialViewSetup()
    }
    
    var childViewController: UIViewController?
    let titleContainerView = UIView()
    
    func initialViewSetup() {
        view.addSubview(navigationToolbar)
        view.addSubview(titleLabel)
        view.addSubview(titleContainerView)
        if let childViewController = self.childViewController {
            self.addChild(childViewController)
            view.addSubview(childViewController.view)
        }
        titleContainerView.addSubview(titleLabel)
    
        titleContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(view.snp.top)
            make.height.equalTo(54)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleContainerView)
            make.centerY.equalTo(titleContainerView)
            make.height.equalTo(30)
        }
        
        navigationToolbar.snp.makeConstraints { make in
            make.leading.trailing.equalTo(view)
            make.top.equalTo(titleContainerView.snp.bottom)
        }

        librarySegmentControl.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(343)
            make.height.equalTo(32)
        }
        
        childViewController?.view.snp.makeConstraints { make in
            make.top.equalTo(navigationToolbar.snp.bottom)
            make.bottom.equalTo(view.snp.bottom)
            make.leading.trailing.equalTo(view)
        }
        
        updateTitle(panel: librarySegmentControl.selectedSegmentIndex)
        applyTheme()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @objc func panelChanged() {
        updateTitle(panel: librarySegmentControl.selectedSegmentIndex)
        switch librarySegmentControl.selectedSegmentIndex {
        case 0:
            print(librarySegmentControl.selectedSegmentIndex)
        case 1:
            print(librarySegmentControl.selectedSegmentIndex)
        case 2:
            print(librarySegmentControl.selectedSegmentIndex)
        case 3:
            print(librarySegmentControl.selectedSegmentIndex)
        default:
            return
        }
    }
    
    func updateTitle(panel: Int) {
        let title = LibraryPanelType(rawValue: panel)?.title
        titleLabel.text = title
    }
    
    func applyTheme() {
        self.view.backgroundColor = fxBackgroundThemeColour
    }
}

extension LibraryNativeViewController: UIToolbarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
