// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import ComponentLibrary

import Security
import CryptoKit
import X509
import SwiftASN1

struct CertificateKeys {
    static let commonName = "CN"
    static let country = "C"
    static let organization = "O"
}

typealias CertificateItems = [(key: String, value: String)]

class CertificatesViewController: UIViewController,
                                  Themeable,
                                  UITableViewDelegate,
                                  UITableViewDataSource {
    private enum CertificatesItemType: Int, CaseIterable {
        case subjectName
        case issuerName
        case validity
        case subjectAltName
    }

    // MARK: - UI
    struct UX {
        static let titleLabelMargin = 8.0
        static let titleLabelTopMargin = 2.0
        static let titleLabelMinHeight = 60.0
        static let headerStackViewMargin = 8.0
        static let headerStackViewTopMargin = 20.0
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.text = .Menu.EnhancedTrackingProtection.certificatesTitle
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
    }

    private let headerView: NavigationHeaderView = .build { header in
        header.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.CertificatesScreen.headerView
    }

    let certificatesTableView: UITableView = .build { tableView in
        tableView.allowsSelection = false
        tableView.register(CertificatesCell.self, forCellReuseIdentifier: CertificatesCell.cellIdentifier)
        tableView.register(CertificatesHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: CertificatesHeaderView.cellIdentifier)
        tableView.sectionHeaderTopPadding = 0
        tableView.separatorInset = .zero
    }

    // MARK: - Variables
    private var constraints = [NSLayoutConstraint]()
    var model: CertificatesModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }
    private let logger: Logger

    // MARK: - View Lifecycle

    init(with viewModel: CertificatesModel,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.model = viewModel
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
        listenForThemeChange(view)
        applyTheme()
    }

    // MARK: View Setup
    private func setupView() {
        setupHeaderView()
        setupTitleConstraints()
        setupCertificatesTableView()
        setupAccessibilityIdentifiers()
    }

    // MARK: Header View Setup
    private func setupHeaderView() {
        view.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: TPMenuUX.UX.popoverTopDistance
            )
        ])
        setupHeaderViewActions()
    }

    // MARK: Header Actions
    private func setupHeaderViewActions() {
        headerView.backToMainMenuCallback = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        headerView.dismissMenuCallback = { [weak self] in
            self?.navigationController?.dismissVC()
        }
    }

    // MARK: Title Setup
    private func setupTitleConstraints() {
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: UX.titleLabelMargin
            ),
            titleLabel.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -UX.titleLabelMargin
            ),
            titleLabel.topAnchor.constraint(
                equalTo: headerView.bottomAnchor,
                constant: UX.titleLabelTopMargin
            )
        ])
    }

    // MARK: TableView Setup
    private func setupCertificatesTableView() {
        certificatesTableView.delegate = self
        certificatesTableView.dataSource = self
        view.addSubview(certificatesTableView)
        NSLayoutConstraint.activate([
            certificatesTableView.topAnchor.constraint(
                equalTo: titleLabel.bottomAnchor
            ),
            certificatesTableView.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: UX.headerStackViewMargin
            ),
            certificatesTableView.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -UX.headerStackViewMargin
            ),
            certificatesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !model.certificates.isEmpty else { return 0 }
        return CertificatesItemType.allCases.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: CertificatesHeaderView.cellIdentifier) as? CertificatesHeaderView else {
            logger.log("Failed to dequeue CertificatesHeaderView with identifier \(CertificatesHeaderView.cellIdentifier)",
                       level: .fatal,
                       category: .certificate)
            return UIView()
        }
        var items: [CertificatesHeaderItem] = []
        for (index, certificate) in model.certificates.enumerated() {
            let certificateValues = certificate.subject.description.getDictionary()
            if !certificateValues.isEmpty, let commonName = certificateValues[CertificateKeys.commonName] {
                let item: CertificatesHeaderItem = .build()
                item.configure(theme: self.currentTheme(),
                               title: commonName,
                               isSelected: model.selectedCertificateIndex == index) { [weak self] in
                    guard let self else { return }
                    self.model.selectedCertificateIndex = index
                    self.certificatesTableView.reloadData()
                }
                items.append(item)
            }
        }
        headerView.configure(withItems: items, theme: currentTheme())
        headerView.setupAccessibilityIdentifiers()
        return headerView
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CertificatesCell.cellIdentifier, for: indexPath)
                as? CertificatesCell else {
            return UITableViewCell()
        }

        guard !model.certificates.isEmpty else {
            return cell
        }

        let certificate = model.certificates[model.selectedCertificateIndex]
        cell.setupAccessibilityIdentifiers()

        switch CertificatesItemType(rawValue: indexPath.row) {
        case .subjectName:
            if let commonName = certificate.subject.description.getDictionary()[CertificateKeys.commonName] {
                cell.configure(theme: currentTheme(),
                               sectionTitle: .Menu.EnhancedTrackingProtection.certificateSubjectName,
                               items: [(.Menu.EnhancedTrackingProtection.certificateCommonName, commonName)])
            }

        case .issuerName:
            let issuerData = certificate.issuer.description.getDictionary()
            if let country = issuerData[CertificateKeys.country],
               let organization = issuerData[CertificateKeys.organization],
               let commonName = issuerData[CertificateKeys.commonName] {
                cell.configure(theme: currentTheme(),
                               sectionTitle: .Menu.EnhancedTrackingProtection.certificateIssuerName,
                               items: [(.Menu.EnhancedTrackingProtection.certificateIssuerCountry, country),
                                       (.Menu.EnhancedTrackingProtection.certificateIssuerOrganization, organization),
                                       (.Menu.EnhancedTrackingProtection.certificateCommonName, commonName)],
                               isIssuerName: true)
            }

        case .validity:
            cell.configure(theme: currentTheme(),
                           sectionTitle: .Menu.EnhancedTrackingProtection.certificateValidity,
                           items: [
                            (.Menu.EnhancedTrackingProtection.certificateValidityNotBefore,
                             certificate.notValidBefore.toRFC822String()),
                            (.Menu.EnhancedTrackingProtection.certificateValidityNotAfter,
                             certificate.notValidAfter.toRFC822String())
                           ])

        case .subjectAltName:
            cell.configure(theme: currentTheme(),
                           sectionTitle: .Menu.EnhancedTrackingProtection.certificateSubjectAltNames,
                           items: model.getDNSNames(for: certificate))
        case .none: break
        }
        return cell
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen
        headerView.setupAccessibility(
            closeButtonA11yLabel: .Menu.EnhancedTrackingProtection.AccessibilityLabels.CloseButton,
            closeButtonA11yId: A11y.closeButton,
            titleA11yId: A11y.titleLabel,
            backButtonA11yLabel: .Menu.EnhancedTrackingProtection.AccessibilityLabels.BackButton,
            backButtonA11yId: A11y.backButton
        )
        titleLabel.accessibilityIdentifier = A11y.certificatesTitleLabel
        certificatesTableView.accessibilityIdentifier = A11y.tableView
    }

    // MARK: View Transitions
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        adjustLayout()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.adjustLayout()
        }, completion: nil)
    }

    private func adjustLayout() {
        headerView.adjustLayout()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func updateViewDetails() {
        certificatesTableView.reloadData()
        headerView.setViews(with: model.topLevelDomain, and: .KeyboardShortcuts.Back)
    }

    // MARK: - Actions
    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }
}

// MARK: - Themable
extension CertificatesViewController {
    func applyTheme() {
        let theme = currentTheme()
        view.backgroundColor = theme.colors.layer3
        titleLabel.textColor = theme.colors.textPrimary
        titleLabel.backgroundColor = theme.colors.layer5
        headerView.applyTheme(theme: theme)
    }
}
