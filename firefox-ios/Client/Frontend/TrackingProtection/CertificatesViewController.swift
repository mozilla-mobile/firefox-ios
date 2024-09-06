// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared
import SiteImageView

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

class CertificatesViewController: UIViewController, Themeable, UITableViewDelegate, UITableViewDataSource {
    private enum CertificatesItemType: Int, CaseIterable {
        case subjectName
        case issuerName
        case validity
        case subjectAltName
    }

    // MARK: - UI
    struct UX {
        static let headerStackViewSpacing = 16.0
        static let titleLabelMargin = 8.0
        static let titleLabelTopMargin = 20.0
        static let headerStackViewMargin = 8.0
        static let headerStackViewTopMargin = 20.0
    }

    private let tableViewHeader: UIView = .build()

    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.text = .Menu.EnhancedTrackingProtection.certificatesTitle
    }

    let certificatesTableView: UITableView = .build { tableView in
        tableView.allowsSelection = false
        tableView.register(CertificatesCell.self, forCellReuseIdentifier: CertificatesCell.cellIdentifier)
    }

    // MARK: - Variables
    private var constraints = [NSLayoutConstraint]()
    var viewModel: CertificatesViewModel
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: - View Lifecycle

    init(with viewModel: CertificatesViewModel,
         windowUUID: WindowUUID,
         and notificationCenter: NotificationProtocol = NotificationCenter.default,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.viewModel = viewModel
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

    private func setupView() {
        constraints.removeAll()
        setupTitleConstraints()
        setupCertificatesTableView()
        setupAccessibilityIdentifiers()
        NSLayoutConstraint.activate(constraints)
    }

    private func setupTitleConstraints() {
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: UX.titleLabelMargin),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -UX.titleLabelMargin),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: UX.titleLabelTopMargin)
        ])
    }

    private func setupCertificatesTableView() {
        certificatesTableView.delegate = self
        certificatesTableView.dataSource = self
        view.addSubview(certificatesTableView)
        NSLayoutConstraint.activate([
            certificatesTableView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                       constant: -UX.headerStackViewTopMargin),
            certificatesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            certificatesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            certificatesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !viewModel.certificates.isEmpty else { return 0 }
        return CertificatesItemType.allCases.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        tableViewHeader.subviews.first?.removeFromSuperview()
        let headerStackView: UIStackView = .build { stack in
            stack.axis = .horizontal
            stack.distribution = .fillEqually
            stack.spacing = UX.headerStackViewSpacing
        }
        for (index, certificate) in viewModel.certificates.enumerated() {
            let certificateValues = viewModel.getCertificateValues(from: "\(certificate.subject)")
            if !certificateValues.isEmpty, let commonName = certificateValues[CertificateKeys.commonName] {
                let item: CertificatesHeaderItem = .build()
                item.configure(theme: self.currentTheme(),
                               title: commonName,
                               isSelected: viewModel.selectedCertificateIndex == index) { [weak self] in
                    guard let self else { return }
                    self.viewModel.selectedCertificateIndex = index
                    self.certificatesTableView.reloadData()
                }
                headerStackView.addArrangedSubview(item)
            }
        }

        view.addSubview(tableViewHeader)
        tableViewHeader.addSubview(headerStackView)

        NSLayoutConstraint.activate([
            tableViewHeader.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewHeader.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewHeader.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),

            headerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerStackView.topAnchor.constraint(equalTo: tableViewHeader.topAnchor,
                                                 constant: UX.headerStackViewTopMargin),
            headerStackView.bottomAnchor.constraint(equalTo: tableViewHeader.bottomAnchor),
        ])

        return tableViewHeader
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CertificatesCell.cellIdentifier, for: indexPath)
                as? CertificatesCell else {
            return UITableViewCell()
        }

        guard !viewModel.certificates.isEmpty else {
            return cell
        }

        let certificate = viewModel.certificates[viewModel.selectedCertificateIndex]

        switch CertificatesItemType(rawValue: indexPath.row) {
        case .subjectName:
            if let commonName = viewModel.getCertificateValues(from: "\(certificate.subject)")[CertificateKeys.commonName] {
                cell.configure(theme: currentTheme(),
                               sectionTitle: .Menu.EnhancedTrackingProtection.certificateSubjectName,
                               items: [(.Menu.EnhancedTrackingProtection.certificateCommonName, commonName)])
            }

        case .issuerName:
            let issuerData = viewModel.getCertificateValues(from: "\(certificate.issuer)")
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
                           items: viewModel.getDNSNames(for: certificate))
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
        self.certificatesTableView.reloadData()
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
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor = theme.colors.layer5
        certificatesTableView.backgroundColor = .clear
        titleLabel.textColor = theme.colors.textPrimary
        tableViewHeader.backgroundColor = theme.colors.layer5
        setNeedsStatusBarAppearanceUpdate()
    }
}
