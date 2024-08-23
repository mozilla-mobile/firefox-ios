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

struct CertificatesUX {
    static let sectionLabelWidth = 150.0
    static let sectionLabelMargin = 20.0
    static let sectionItemsSpacing = 40.0
    static let allSectionItemsSpacing = 10.0
    static let allSectionItemsTopMargin = 20.0
    static let headerStackViewSpacing = 16.0
    static let titleLabelMargin = 8.0
    static let titleLabelTopMargin = 20.0
    static let headerStackViewMargin = 8.0
    static let headerStackViewTopMargin = 20.0
    static let tableViewSpacerTopMargin = 20.0
    static let tableViewSpacerHeight = 1.0
    static let tableViewTopMargin = 20.0
}

typealias CertificateItems = [(key: String, value: [String])]

class CertificatesViewController: UIViewController, Themeable, UITableViewDelegate, UITableViewDataSource {
    // MARK: - UI
    private let titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Bold.title1.scaledFont()
        label.text = .Menu.EnhancedTrackingProtection.certificatesTitle
    }

    private let headerStackView: UIStackView = .build { stack in
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = CertificatesUX.headerStackViewSpacing
        stack.translatesAutoresizingMaskIntoConstraints = false
    }

    private let tableViewTopSpacer: UIView = .build { view in
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Variables
    let certificatesTableView = UITableView()
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
        setupCertificatesHeaderView()
        setupCertificatesTableView()
        setupAccessibilityIdentifiers()
        NSLayoutConstraint.activate(constraints)
    }

    private func setupTitleConstraints() {
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: CertificatesUX.titleLabelMargin),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -CertificatesUX.titleLabelMargin),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: CertificatesUX.titleLabelTopMargin)
        ])
    }

    private func setupCertificatesHeaderView() {
        // TODO: FXIOS-9834 Add tab indicator for table view tabs and hide/unhide it on selection
        for (index, certificate) in viewModel.certificates.enumerated() {
            let button: UIButton = .build { [weak self] button in
                button.setTitle(self?.viewModel.getCertificateValues(from: "\(certificate.subject)")[CertificateKeys.commonName], for: .normal)
                button.setTitleColor(self?.currentTheme().colors.textPrimary, for: .normal)
                button.configuration?.titleLineBreakMode = .byWordWrapping
                button.titleLabel?.numberOfLines = 2
                button.titleLabel?.textAlignment = .center
                button.tag = index
                button.addTarget(self, action: #selector(self?.certificateButtonTapped(_:)), for: .touchUpInside)
            }
            headerStackView.addArrangedSubview(button)
        }

        view.addSubview(headerStackView)

        NSLayoutConstraint.activate([
            headerStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                     constant: CertificatesUX.headerStackViewMargin),
            headerStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                      constant: -CertificatesUX.headerStackViewMargin),
            headerStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                 constant: CertificatesUX.headerStackViewTopMargin)
        ])
    }

    private func setupCertificatesTableView() {
        certificatesTableView.allowsSelection = false
        certificatesTableView.delegate = self
        certificatesTableView.dataSource = self
        certificatesTableView.register(CertificatesCell.self, forCellReuseIdentifier: CertificatesCell.cellIdentifier)

        view.addSubview(tableViewTopSpacer)
        view.addSubview(certificatesTableView)
        certificatesTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableViewTopSpacer.topAnchor.constraint(equalTo: headerStackView.bottomAnchor,
                                                    constant: CertificatesUX.tableViewSpacerTopMargin),
            tableViewTopSpacer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableViewTopSpacer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableViewTopSpacer.heightAnchor.constraint(equalToConstant: CertificatesUX.tableViewSpacerHeight),

            certificatesTableView.topAnchor.constraint(equalTo: tableViewTopSpacer.bottomAnchor,
                                                       constant: CertificatesUX.tableViewTopMargin),
            certificatesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            certificatesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            certificatesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc
    private func certificateButtonTapped(_ sender: UIButton) {
        viewModel.selectedCertificateIndex = sender.tag
        certificatesTableView.reloadData()
    }

    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !viewModel.certificates.isEmpty else { return 0 }
        return 4
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

        switch indexPath.row {
        case 0:
            if let commonName = viewModel.getCertificateValues(from: "\(certificate.subject)")[CertificateKeys.commonName] {
                cell.configure(theme: currentTheme(),
                               sectionTitle: .Menu.EnhancedTrackingProtection.certificateSubjectName,
                               items: [(.Menu.EnhancedTrackingProtection.certificateCommonName, [commonName])])
            }

        case 1:
            let issuerData = viewModel.getCertificateValues(from: "\(certificate.issuer)")
            if let country = issuerData[CertificateKeys.country],
               let organization = issuerData[CertificateKeys.organization],
               let commonName = issuerData[CertificateKeys.commonName] {
                cell.configure(theme: currentTheme(),
                               sectionTitle: .Menu.EnhancedTrackingProtection.certificateIssuerName,
                               items: [(.Menu.EnhancedTrackingProtection.certificateIssuerCountry, [country]),
                                       (.Menu.EnhancedTrackingProtection.certificateIssuerOrganization, [organization]),
                                       (.Menu.EnhancedTrackingProtection.certificateCommonName, [commonName])])
            }

        case 2:
            cell.configure(theme: currentTheme(),
                           sectionTitle: .Menu.EnhancedTrackingProtection.certificateValidity,
                           items: [
                            (.Menu.EnhancedTrackingProtection.certificateValidityNotBefore,
                                [certificate.notValidBefore.toRFC822String()]),
                            (.Menu.EnhancedTrackingProtection.certificateValidityNotAfter,
                                [certificate.notValidAfter.toRFC822String()])
                           ])

        case 3:
            cell.configure(theme: currentTheme(),
                           sectionTitle: .Menu.EnhancedTrackingProtection.certificateSubjectAltNames,
                           items: viewModel.getDNSNames(for: certificate))
        default: break
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
        titleLabel.textColor = theme.colors.textPrimary
        tableViewTopSpacer.backgroundColor = theme.colors.layer1
        setNeedsStatusBarAppearanceUpdate()
    }
}
