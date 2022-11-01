// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class PageActionMenu: UIViewController, UIGestureRecognizerDelegate {

    struct UX {
        static let Spacing: CGFloat = 16
        static let Cell = "Cell"
        static let Shortcuts = "Shortcuts"
        static let RowHeight: CGFloat = 50
    }

    // MARK: - Variables
    private var tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var knob = UIView()
    let viewModel: PhotonActionSheetViewModel
    weak var delegate: PageActionsShortcutsDelegate?

    // MARK: - Init

    init(viewModel: PhotonActionSheetViewModel, delegate: PageActionsShortcutsDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
        modalPresentationStyle = viewModel.modalStyle
        tableView.estimatedRowHeight = UX.RowHeight
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PageActionMenuCell.self, forCellReuseIdentifier: UX.Cell)
        tableView.register(PageActionsShortcutsHeader.self, forHeaderFooterViewReuseIdentifier: UX.Shortcuts)
        tableView.estimatedSectionHeaderHeight = UX.Spacing
        tableView.sectionFooterHeight = 0
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(knob)
        knob.layer.cornerRadius = 2

        setupConstraints()
        applyTheme()
    }

    // MARK: - Setup

    private func setupConstraints() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        knob.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            knob.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            knob.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            knob.widthAnchor.constraint(equalToConstant: 32),
            knob.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    private var contentSizeObserver : NSKeyValueObservation?
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkSwipeDown()

        guard traitCollection.userInterfaceIdiom == .pad else { return }
        contentSizeObserver = tableView.observe(\.contentSize) { [weak self] tableView, _ in
            self?.preferredContentSize = CGSize(width: 350, height: tableView.contentSize.height)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        contentSizeObserver?.invalidate()
        contentSizeObserver = nil
    }

    // MARK: Swipe down to close in iPhone Landscape
    lazy var swipeDown: UISwipeGestureRecognizer = {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(close))
        swipeDown.direction = .down
        swipeDown.isEnabled = false
        swipeDown.delegate = self
        view.addGestureRecognizer(swipeDown)
        return swipeDown
    }()

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === swipeDown else { return false }
        return tableView.contentOffset.y <= 0
    }

    private func checkSwipeDown() {
        guard traitCollection.userInterfaceIdiom == .phone,
                let window = UIApplication.shared.windows.first(where: \.isKeyWindow),
                let orientation = window.windowScene?.interfaceOrientation else { return }

        swipeDown.isEnabled = orientation.isLandscape
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        checkSwipeDown()
    }

    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension PageActionMenu: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.actions.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.actions[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UX.Cell, for: indexPath)
        cell.separatorInset.left = UX.Spacing
        cell.backgroundColor = .theme.ecosia.impactMultiplyCardBackground
        let actions = viewModel.actions[indexPath.section][indexPath.row]
        let item = actions.item

        cell.textLabel?.text = item.currentTitle
        cell.textLabel?.textColor = .theme.ecosia.primaryText
        cell.detailTextLabel?.text = item.text
        cell.detailTextLabel?.textColor = .theme.ecosia.secondaryText

        cell.accessibilityIdentifier = item.iconString ?? item.accessibilityId
        cell.accessibilityLabel = item.currentTitle

        if let iconName = item.iconString {
            cell.imageView?.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
            cell.imageView?.tintColor = .theme.ecosia.secondaryText
        } else {
            cell.imageView?.image = nil
        }
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return UITableView.automaticDimension
        } else {
            return UX.Spacing
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return UIView() }

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: UX.Shortcuts) as! PageActionsShortcutsHeader
        header.delegate = delegate
        return header
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let actions = viewModel.actions[indexPath.section][indexPath.row]
        let item = actions.item
        dismiss(animated: true) {
            if let handler = item.tapHandler {
                handler(item)
            }
        }
    }
}

// MARK: - NotificationThemeable
extension PageActionMenu: NotificationThemeable {

    func applyTheme() {
        tableView.reloadData()
        tableView.backgroundColor = .theme.ecosia.modalBackground
        tableView.separatorColor = .theme.ecosia.border
        knob.backgroundColor = .theme.ecosia.secondaryText
    }
}

// MARK: Cell

class PageActionMenuCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
