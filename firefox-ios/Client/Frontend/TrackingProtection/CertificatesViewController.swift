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
        static let closeButtonSize = 20.0
    }

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.text = .Menu.EnhancedTrackingProtection.certificatesTitle
        label.textAlignment = .left
        label.adjustsFontSizeToFitWidth = true
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
    var themeListenerCancellable: Any?
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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()

        listenForThemeChanges(withNotificationCenter: notificationCenter)
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateViewDetails()
    }

    // MARK: View Setup
    private func setupView() {
        setupCloseButton()

        setupTitleConstraints()
        setupCertificatesTableView()
        setupAccessibilityIdentifiers()
    }

    // MARK: Header Actions
    @objc
    private func dismissVC() {
        navigationController?.dismissVC()
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
                equalTo: view.safeAreaLayoutGuide.topAnchor,
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

    // MARK: Close Button
    private func setupCloseButton() {
        let closeButtonSize = CGSize(width: UX.closeButtonSize, height: UX.closeButtonSize)

        let rawImage = UIImage(named: StandardImageIdentifiers.Large.cross)
        let resizedImage = UIGraphicsImageRenderer(size: closeButtonSize).image { _ in
            rawImage?.draw(in: CGRect(origin: .zero, size: closeButtonSize))
        }.withRenderingMode(.alwaysTemplate)

        let closeBarButtonItem = UIBarButtonItem(
            image: resizedImage,
            style: .plain,
            target: self,
            action: #selector(dismissVC)
        )

        typealias A11y = AccessibilityIdentifiers.EnhancedTrackingProtection.DetailsScreen
        closeBarButtonItem.accessibilityIdentifier = A11y.closeButton
        closeBarButtonItem.accessibilityLabel = .Menu.EnhancedTrackingProtection.AccessibilityLabels.CloseButton

        closeBarButtonItem.tintColor = currentTheme().colors.iconPrimary
        navigationItem.rightBarButtonItem = closeBarButtonItem
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
        titleLabel.accessibilityIdentifier = A11y.certificatesTitleLabel
        certificatesTableView.accessibilityIdentifier = A11y.tableView
    }

    private func updateViewDetails() {
        certificatesTableView.reloadData()
        self.title = model.topLevelDomain
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
    }
}
