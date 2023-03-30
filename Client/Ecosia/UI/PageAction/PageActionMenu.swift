// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

final class PageActionMenu: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - UX

    struct UX {
        static let spacing: CGFloat = 16
        static let estimatedSectionHeaderHeight: CGFloat = 16
        static let shortcuts = "Shortcuts"
        static let rowHeight: CGFloat = 50
    }

    // MARK: - Variables
    
    private var tableView = UITableView(frame: .zero, style: .plain)
    private var knob = UIView()
    private var contentSizeObserver : NSKeyValueObservation?
    private lazy var swipeDown: UISwipeGestureRecognizer = {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(close))
        swipeDown.direction = .down
        swipeDown.isEnabled = false
        swipeDown.delegate = self
        view.addGestureRecognizer(swipeDown)
        return swipeDown
    }()
    
    private let viewModel: PhotonActionSheetViewModel
    private weak var delegate: PageActionsShortcutsDelegate?

    // MARK: - Init

    init(viewModel: PhotonActionSheetViewModel, delegate: PageActionsShortcutsDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)

        title = viewModel.title
        modalPresentationStyle = viewModel.modalStyle
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupKnob()
        setupConstraints()
        applyTheme()
    }

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
}

// MARK: Swipe down to close in iPhone Landscape

extension PageActionMenu {
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        checkSwipeDown()
    }

    @objc func close() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Gestures

extension PageActionMenu {
    
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
}

// MARK: - Setup PageActionMenu

extension PageActionMenu {
        
    private func setupTableView() {
        view.addSubview(tableView)
        tableView.estimatedRowHeight = UX.rowHeight
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PageActionMenuCell.self, forCellReuseIdentifier: PageActionMenuCell.UX.cellIdentifier)
        tableView.register(PageActionsShortcutsHeader.self, forHeaderFooterViewReuseIdentifier: UX.shortcuts)
        tableView.estimatedSectionHeaderHeight = UX.estimatedSectionHeaderHeight
        tableView.sectionFooterHeight = 0
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    private func setupKnob() {
        view.addSubview(knob)
        knob.translatesAutoresizingMaskIntoConstraints = false
        knob.layer.cornerRadius = 2
    }

    private func setupConstraints() {
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
        let cell = tableView.dequeueReusableCell(withIdentifier: PageActionMenuCell.UX.cellIdentifier, for: indexPath) as! PageActionMenuCell
        cell.determineTableViewCellPositionAt(indexPath, forActions: viewModel.actions)
        cell.configure(with: viewModel, at: indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return UITableView.automaticDimension
        } else {
            return UX.spacing
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else { return UIView() }

        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: UX.shortcuts) as! PageActionsShortcutsHeader
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
