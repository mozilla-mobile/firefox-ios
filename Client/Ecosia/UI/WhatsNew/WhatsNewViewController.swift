// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core
import Common

protocol WhatsNewViewDelegate: AnyObject {
    func whatsNewViewDidShow(_ viewController: WhatsNewViewController)
}

final class WhatsNewViewController: UIViewController, Themeable {
    
    // MARK: - UX
    
    private struct UX {
        private init() {}
        static let defaultPadding: CGFloat = 16

        struct PreferredContentSize {
            private init() {}
            static let iPadWidth: CGFloat = 544
            static let iPadHeight: CGFloat = 600
            static let iPhoneCustomDetentHeight: CGFloat = 560
        }
        
        struct ForestAndWaves {
            private init() {}
            static let waveHeight: CGFloat = 34
        }
        
        struct Knob {
            private init() {}
            static let height: CGFloat = 4
            static let width: CGFloat = 32
            static let cornerRadious: CGFloat = 2
        }

        struct CloseButton {
            private init() {}
            static let size: CGFloat = 32
            static let distanceFromCardBottom: CGFloat = 32
        }
        
        struct FooterButton {
            private init() {}
            static let height: CGFloat = 50
        }
    }
    
    // MARK: - Properties
    
    private var viewModel: WhatsNewViewModel!
    private let knob = UIView()
    private let firstImageView = UIImageView(image: .init(named: "whatsNewTrees"))
    private let secondImageView = UIImageView(image: .init(named: "waves"))
    private let closeButton = UIButton()
    private let headerLabel = UILabel()
    private let topContainerView = UIView()
    private let headerLabelContainerView = UIView()
    private let tableView = UITableView()
    private let footerButton = UIButton()
    private let images = Images(.init(configuration: .ephemeral))
    weak var delegate: WhatsNewViewDelegate?

    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    init(viewModel: WhatsNewViewModel, delegate: WhatsNewViewDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        layoutViews()
        applyTheme()
        updateTableView()
        listenForThemeChange(view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        modalTransitionStyle = .crossDissolve
        self.delegate?.whatsNewViewDidShow(self)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

// MARK: - Buttons Actions

extension WhatsNewViewController {
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func footerButtonTapped() {
        closeButtonTapped()
    }
}

// MARK: - View Setup Helpers

extension WhatsNewViewController {
    
    private func setupViews() {
        
        knob.translatesAutoresizingMaskIntoConstraints = false
        knob.layer.cornerRadius = UX.Knob.cornerRadious

        closeButton.setImage(UIImage(named: "xmark"), for: .normal)
        closeButton.imageView?.contentMode = .scaleAspectFill
        closeButton.layer.cornerRadius = UX.CloseButton.size/2
        closeButton.contentVerticalAlignment = .fill
        closeButton.contentHorizontalAlignment = .fill
        closeButton.imageEdgeInsets = UIEdgeInsets(equalInset: 10)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        
        headerLabelContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = .localized(.whatsNewViewTitle)
        headerLabel.textAlignment = .center
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.font = .preferredFont(forTextStyle: .title3).bold()
        headerLabelContainerView.addSubview(headerLabel)

        topContainerView.translatesAutoresizingMaskIntoConstraints = false
        firstImageView.translatesAutoresizingMaskIntoConstraints = false
        secondImageView.translatesAutoresizingMaskIntoConstraints = false
        topContainerView.addSubview(firstImageView)
        topContainerView.insertSubview(secondImageView, aboveSubview: firstImageView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(WhatsNewCell.self, forCellReuseIdentifier: WhatsNewCell.cellIdentifier)
        
        footerButton.setTitle(.localized(.whatsNewFooterButtonTitle), for: .normal)
        footerButton.translatesAutoresizingMaskIntoConstraints = false
        footerButton.addTarget(self, action: #selector(footerButtonTapped), for: .touchUpInside)
        footerButton.layer.cornerRadius = UX.FooterButton.height/2
        
        topContainerView.addSubview(knob)
        topContainerView.addSubview(closeButton)
        view.addSubview(topContainerView)
        view.addSubview(headerLabelContainerView)
        view.addSubview(tableView)
        view.addSubview(footerButton)
    }
    
    private func layoutViews() {
        
        NSLayoutConstraint.activate([
            
            // Top Container View Constraints
            topContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            topContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Knob view constraints
            knob.topAnchor.constraint(equalTo: topContainerView.topAnchor, constant: UX.defaultPadding/2),
            knob.centerXAnchor.constraint(equalTo: topContainerView.centerXAnchor),
            knob.widthAnchor.constraint(equalToConstant: UX.Knob.width),
            knob.heightAnchor.constraint(equalToConstant: UX.Knob.height),

            // Close button constraints
            closeButton.topAnchor.constraint(equalTo: topContainerView.topAnchor, constant: UX.defaultPadding),
            closeButton.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor, constant: -UX.defaultPadding),
            closeButton.widthAnchor.constraint(equalToConstant: UX.CloseButton.size),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),

            // First image view constraints
            firstImageView.topAnchor.constraint(equalTo: knob.bottomAnchor, constant: UX.defaultPadding),
            firstImageView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            firstImageView.centerXAnchor.constraint(equalTo: topContainerView.centerXAnchor),

            // Second image view constraints
            secondImageView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            secondImageView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            secondImageView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            secondImageView.heightAnchor.constraint(equalToConstant: UX.ForestAndWaves.waveHeight),

            // Header Label Container View Constraints
            headerLabelContainerView.topAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            headerLabelContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLabelContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Header label constraints
            headerLabel.topAnchor.constraint(equalTo: headerLabelContainerView.topAnchor, constant: UX.defaultPadding),
            headerLabel.bottomAnchor.constraint(equalTo: headerLabelContainerView.bottomAnchor, constant: -UX.defaultPadding),
            headerLabel.centerXAnchor.constraint(equalTo: headerLabelContainerView.centerXAnchor),

            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerLabelContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: footerButton.topAnchor),
            
            // Footer button constraints
            footerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UX.defaultPadding),
            footerButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.defaultPadding),
            footerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.defaultPadding),
            footerButton.heightAnchor.constraint(equalToConstant: UX.FooterButton.height)
        ])
    }
    
    private func updateTableView() {
        tableView.reloadData()
    }
}

// MARK: - TableView Data Source

extension WhatsNewViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WhatsNewCell.cellIdentifier, for: indexPath) as! WhatsNewCell
        let item = viewModel.items[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - Themeable

extension WhatsNewViewController {

    func applyTheme() {
        view.backgroundColor = .legacyTheme.ecosia.primaryBackground
        topContainerView.backgroundColor = .legacyTheme.ecosia.tertiaryBackground
        tableView.backgroundColor = .legacyTheme.ecosia.primaryBackground
        tableView.separatorColor = .clear
        knob.backgroundColor = .legacyTheme.ecosia.secondaryText
        closeButton.backgroundColor = .legacyTheme.ecosia.primaryBackground
        closeButton.tintColor = .legacyTheme.ecosia.whatsNewCloseButton
        footerButton.backgroundColor = .legacyTheme.ecosia.primaryBrand
        footerButton.setTitleColor(.legacyTheme.ecosia.primaryTextInverted, for: .normal)
        headerLabelContainerView.backgroundColor = .legacyTheme.ecosia.primaryBackground
        secondImageView.tintColor = .legacyTheme.ecosia.primaryBackground
    }
}

// MARK: - Presentation

extension WhatsNewViewController {
    
    static func presentOn(_ viewController: UIViewController, 
                          viewModel: WhatsNewViewModel) {
        
        guard let whatsNewDelegateViewController = viewController as? WhatsNewViewDelegate else { return }
        let sheet = WhatsNewViewController(viewModel: viewModel,
                                           delegate: whatsNewDelegateViewController)
        sheet.modalPresentationStyle = .automatic
        
        // iPhone
        if sheet.traitCollection.userInterfaceIdiom == .phone {
            if #available(iOS 16.0, *), let sheet = sheet.sheetPresentationController {
                let custom = UISheetPresentationController.Detent.custom { context in
                    return UX.PreferredContentSize.iPhoneCustomDetentHeight
                }
                sheet.detents = [custom, .large()]
            } else if #available(iOS 15.0, *), let sheet = sheet.sheetPresentationController {
                sheet.detents = [.large()]
            }
        }

        // iPad
        if sheet.traitCollection.userInterfaceIdiom == .pad {
            sheet.modalPresentationStyle = .formSheet
            sheet.preferredContentSize = .init(width: UX.PreferredContentSize.iPadWidth,
                                         height: UX.PreferredContentSize.iPadHeight)
        }
        
        viewController.present(sheet, animated: true, completion: nil)
    }
}
