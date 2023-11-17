// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core
import Common

protocol APNConsentViewDelegate: AnyObject {
    func apnConsentViewDidShow(_ viewController: APNConsentViewController)
}

final class APNConsentViewController: UIViewController, Themeable {
    
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
        
        struct Waves {
            private init() {}
            static let waveHeight: CGFloat = 34
        }
                
        struct FooterButtons {
            private init() {}
            static let height: CGFloat = 50
        }
    }
    
    // MARK: - Properties
    
    private var viewModel: APNConsentViewModelProtocol!
    private var firstImageView = UIImageView()
    private let secondImageView = UIImageView(image: .init(named: "waves"))
    private let headerLabel = UILabel()
    private let topContainerView = UIView()
    private let headerLabelContainerView = UIView()
    private let tableView = UITableView()
    private let ctaButton = UIButton()
    private let skipButton = UIButton()
    weak var delegate: APNConsentViewDelegate?
    
    // MARK: - Themeable Properties
    
    var themeManager: ThemeManager { AppContainer.shared.resolve() }
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Init

    init(viewModel: APNConsentViewModelProtocol, delegate: APNConsentViewDelegate?) {
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
        listenForThemeChange(view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        modalTransitionStyle = .crossDissolve
        Analytics.shared.apnConsent(.view)
        self.delegate?.apnConsentViewDidShow(self)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        traitCollection.userInterfaceIdiom == .pad ? .all : .portrait
    }
}

// MARK: - Buttons Actions

extension APNConsentViewController {
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func footerButtonTapped() {
        closeButtonTapped()
    }
}

// MARK: - View Setup Helpers

extension APNConsentViewController {
    
    private func setupViews() {
        
        firstImageView = UIImageView(image: viewModel.image)
        firstImageView.contentMode = .scaleAspectFill
        firstImageView.clipsToBounds = true
        firstImageView.translatesAutoresizingMaskIntoConstraints = false
        firstImageView.setContentCompressionResistancePriority(.required, for: .vertical)
        firstImageView.setContentHuggingPriority(.required, for: .vertical)

        headerLabelContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = viewModel.title
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.adjustsFontForContentSizeCategory = true
        headerLabel.font = .preferredFont(forTextStyle: .title3).bold()
        headerLabelContainerView.addSubview(headerLabel)

        topContainerView.translatesAutoresizingMaskIntoConstraints = false
        secondImageView.translatesAutoresizingMaskIntoConstraints = false
        topContainerView.addSubview(firstImageView)
        topContainerView.insertSubview(secondImageView, aboveSubview: firstImageView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(APNConsentItemCell.self, forCellReuseIdentifier: APNConsentItemCell.cellIdentifier)
        
        ctaButton.setTitle(viewModel.ctaAllowButtonTitle, for: .normal)
        ctaButton.titleLabel?.adjustsFontForContentSizeCategory = true
        ctaButton.translatesAutoresizingMaskIntoConstraints = false
        ctaButton.addTarget(self, action: #selector(footerButtonTapped), for: .touchUpInside)
        ctaButton.layer.cornerRadius = UX.FooterButtons.height/2
        ctaButton.addTarget(self, action: #selector(ctaTapped), for: .primaryActionTriggered)

        skipButton.translatesAutoresizingMaskIntoConstraints = false
        skipButton.backgroundColor = .clear
        skipButton.titleLabel?.font = .preferredFont(forTextStyle: .callout)
        skipButton.titleLabel?.adjustsFontForContentSizeCategory = true
        skipButton.setTitle(.localized(.apnConsentSkipButtonTitle), for: .normal)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .primaryActionTriggered)
        
        view.addSubview(topContainerView)
        view.addSubview(headerLabelContainerView)
        view.addSubview(tableView)
        view.addSubview(ctaButton)
        view.addSubview(skipButton)
    }
    
    private func layoutViews() {
        
        NSLayoutConstraint.activate([
            
            // Top Container View Constraints
            topContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            topContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // First image view constraints
            firstImageView.topAnchor.constraint(equalTo: topContainerView.topAnchor),
            firstImageView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            firstImageView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            firstImageView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),

            // Second image view constraints
            secondImageView.bottomAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            secondImageView.leadingAnchor.constraint(equalTo: topContainerView.leadingAnchor),
            secondImageView.trailingAnchor.constraint(equalTo: topContainerView.trailingAnchor),
            secondImageView.heightAnchor.constraint(equalToConstant: UX.Waves.waveHeight),

            // Header Label Container View Constraints
            headerLabelContainerView.topAnchor.constraint(equalTo: topContainerView.bottomAnchor),
            headerLabelContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerLabelContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Header label constraints
            headerLabel.topAnchor.constraint(equalTo: headerLabelContainerView.topAnchor, constant: UX.defaultPadding),
            headerLabel.bottomAnchor.constraint(equalTo: headerLabelContainerView.bottomAnchor, constant: -UX.defaultPadding),
            headerLabel.leadingAnchor.constraint(equalTo: headerLabelContainerView.leadingAnchor, constant: UX.defaultPadding),
            headerLabel.trailingAnchor.constraint(equalTo: headerLabelContainerView.trailingAnchor),

            // Table view constraints
            tableView.topAnchor.constraint(equalTo: headerLabelContainerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: ctaButton.topAnchor),
            
            // Footer button constraints
            ctaButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.defaultPadding),
            ctaButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.defaultPadding),
            ctaButton.heightAnchor.constraint(equalToConstant: UX.FooterButtons.height),
            ctaButton.bottomAnchor.constraint(equalTo: skipButton.topAnchor),

            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -UX.defaultPadding),
            skipButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.defaultPadding),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.defaultPadding),
            skipButton.heightAnchor.constraint(equalTo: ctaButton.heightAnchor)
        ])
    }
    
    private func updateTableView() {
        tableView.reloadData()
    }
}

// MARK: - Button's Actions

extension APNConsentViewController {

    @objc private func skipTapped() {
        Analytics.shared.apnConsent(.skip)
        dismiss(animated: true)
    }

    @objc private func ctaTapped() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        ClientEngagementService.shared.requestAPNConsent(notificationCenterDelegate: appDelegate) { granted, error in
            guard granted else {
                Analytics.shared.apnConsent(.deny)
                return
            }
            Analytics.shared.apnConsent(.allow)
        }
    }
}

// MARK: - TableView Data Source

extension APNConsentViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.listItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: APNConsentItemCell.cellIdentifier, for: indexPath) as! APNConsentItemCell
        let item = viewModel.listItems[indexPath.row]
        cell.configure(with: item)
        return cell
    }
}

// MARK: - NotificationThemeable

extension APNConsentViewController {

    func applyTheme() {
        view.backgroundColor = .legacyTheme.ecosia.primaryBackground
        topContainerView.backgroundColor = .legacyTheme.ecosia.tertiaryBackground
        tableView.backgroundColor = .legacyTheme.ecosia.primaryBackground
        tableView.separatorColor = .clear
        ctaButton.backgroundColor = .legacyTheme.ecosia.primaryBrand
        ctaButton.setTitleColor(.legacyTheme.ecosia.primaryTextInverted, for: .normal)
        skipButton.setTitleColor(.legacyTheme.ecosia.primaryButton, for: .normal)
        headerLabelContainerView.backgroundColor = .legacyTheme.ecosia.primaryBackground
        secondImageView.tintColor = .legacyTheme.ecosia.primaryBackground
        /*
         Updating the TableView here so that the items containing the image will update the theming
         showing the correct `tintColor`
        */
        updateTableView()
    }
}

// MARK: - Presentation

extension APNConsentViewController {
    
    static func presentOn(_ viewController: UIViewController,
                          viewModel: APNConsentViewModelProtocol) {
        
        guard let whatsNewDelegateViewController = viewController as? APNConsentViewDelegate else { return }
        let sheet = APNConsentViewController(viewModel: viewModel,
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
