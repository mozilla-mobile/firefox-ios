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

struct CertificatesViewModel {
    let topLevelDomain: String
    let title: String
    let URL: String
    var certificates = [Certificate]()
    var selectedCertificateIndex: Int = 0

    let getLockIcon: (ThemeType) -> UIImage
}

class CertificatesViewController: UIViewController, Themeable, UITableViewDelegate, UITableViewDataSource {
    // MARK: - UI
    private let scrollView: UIScrollView = .build { scrollView in }
    private let baseView: UIView = .build { view in }

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
        setupCertificatesTableView()
        setupAccessibilityIdentifiers()
        NSLayoutConstraint.activate(constraints)
    }

    private func setupCertificatesTableView() {
        view.backgroundColor = .white
        title = "Certificates"

        certificatesTableView.delegate = self
        certificatesTableView.dataSource = self
        certificatesTableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        view.addSubview(certificatesTableView)
        certificatesTableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            certificatesTableView.topAnchor.constraint(equalTo: view.topAnchor),
            certificatesTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            certificatesTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            certificatesTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        setupTableHeaderView()
    }

    private func setupTableHeaderView() {
        let headerView = UIView()
        headerView.backgroundColor = .white

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 8

        for (index, certificate) in viewModel.certificates.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(certificate.subject.description, for: .normal)
            button.tag = index
            button.addTarget(self, action: #selector(certificateButtonTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(button)
        }

        headerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -8),
            stackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])

        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 50)
        certificatesTableView.tableHeaderView = headerView
    }

    @objc private func certificateButtonTapped(_ sender: UIButton) {
        viewModel.selectedCertificateIndex = sender.tag
        certificatesTableView.reloadData()
    }

    // MARK: - UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 6 // Title, Domain & Certificate Type, Subject Name, Issuer Name, Validity, Subject Alt Names
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !viewModel.certificates.isEmpty else { return 0 }

//        let certificate = viewModel.certificates[viewModel.selectedCertificateIndex]

        switch section {
        case 0: return 1
        case 1: return 1
        case 2: return 1
        case 3: return 1
        case 4: return 2
        case 5: return 1 // Displaying extensions as a single string
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return nil
        case 1: return nil
        case 2: return "Subject Name"
        case 3: return "Issuer Name"
        case 4: return "Validity"
        case 5: return "Subject Alt Names"
        default: return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        guard !viewModel.certificates.isEmpty else {
            return cell
        }

        let certificate = viewModel.certificates[viewModel.selectedCertificateIndex]

        switch indexPath.section {
        case 0:
            cell.textLabel?.text = "Certificate"
            cell.textLabel?.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        case 1:
            cell.textLabel?.text = "\(certificate.subject)\n\(certificate.signatureAlgorithm)\n\(certificate.issuer)"
            cell.textLabel?.textColor = .blue
            cell.textLabel?.numberOfLines = 3
        case 2:
            cell.textLabel?.text = "\(certificate.subject)"
        case 3:
            let details = ["Country: \(certificate.issuer)", "Organization: \(certificate.issuer)", "Common Name: \(certificate.issuer)"]
            cell.textLabel?.text = details[indexPath.row]
        case 4:
            let details = ["Not Before: \(certificate.notValidBefore)", "Not After: \(certificate.notValidAfter)"]
            cell.textLabel?.text = details[indexPath.row]
        case 5:
            cell.textLabel?.text = "\(certificate.extensions[indexPath.row])"
        default:
            cell.textLabel?.text = ""
        }

        return cell
    }

    // MARK: Accessibility
    private func setupAccessibilityIdentifiers() {
//        view.accessibilityIdentifier = viewModel.blockedTrackersViewA11yId
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
//        let iconSize = TPMenuUX.UX.iconSize

        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    private func updateViewDetails() {
        self.certificatesTableView.reloadData()
    }

    // MARK: - Actions

    @objc
    func closeButtonTapped() {
        self.dismiss(animated: true)
    }

    private func currentTheme() -> Theme {
        return themeManager.getCurrentTheme(for: windowUUID)
    }
}

// MARK: - Themable
extension CertificatesViewController {
    func applyTheme() {
        let theme = currentTheme()
        overrideUserInterfaceStyle = theme.type.getInterfaceStyle()
        view.backgroundColor =  theme.colors.layer1

        setNeedsStatusBarAppearanceUpdate()
    }
}
