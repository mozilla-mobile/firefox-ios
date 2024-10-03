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
        static let titleLabelTopMargin = 20.0
        static let headerStackViewMargin = 8.0
        static let headerStackViewTopMargin = 20.0
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.text = .Menu.EnhancedTrackingProtection.certificatesTitle
    }

    private let headerView: NavigationHeaderView = .build { header in
        header.accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.CertificatesScreen.headerView
    }

    // TODO: FXIOS-9980 Tracking Protection Certificates Screen tableView header text is a little bit cutted off
    let certificatesTableView: UITableView = .build { tableView in
        tableView.allowsSelection = false
        tableView.register(CertificatesCell.self, forCellReuseIdentifier: CertificatesCell.cellIdentifier)
        tableView.register(CertificatesHeaderView.self,
                           forHeaderFooterViewReuseIdentifier: CertificatesHeaderView.cellIdentifier)
        tableView.sectionHeaderTopPadding = 0
    }

    // MARK: - Variables
    private var constraints = [NSLayoutConstraint]()
    var model: CertificatesModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - View Lifecycle

    init(with viewModel: CertificatesModel,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.model = viewModel
        self.windowUUID = windowUUID
        self.notificationCenter = notificationCenter
        self.themeManager = themeManager
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
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.titleLabelMargin),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.titleLabelMargin),
            titleLabel.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: UX.titleLabelTopMargin)
        ])
    }

    // MARK: TableView Setup
    private func setupCertificatesTableView() {
        certificatesTableView.delegate = self
        certificatesTableView.dataSource = self
        view.addSubview(certificatesTableView)
        NSLayoutConstraint.activate([
            certificatesTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                       constant: UX.titleLabelTopMargin),
            certificatesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            certificatesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            certificatesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !model.certificates.isEmpty else { return 0 }
        return CertificatesItemType.allCases.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: CertificatesHeaderView.cellIdentifier) as! CertificatesHeaderView
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
                                       (.Menu.EnhancedTrackingProtection.certificateCommonName, commonName)])
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
        // TODO: FXIOS-9829 Enhanced Tracking Protection certificates details screen accessibility identifiers
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
        view.backgroundColor = theme.colors.layer5
        titleLabel.textColor = theme.colors.textPrimary
        titleLabel.backgroundColor = theme.colors.layer5
        headerView.applyTheme(theme: theme)
    }
}
