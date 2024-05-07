/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class AutocompleteCustomUrlViewController: UIViewController {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundView = emptyStateView
        tableView.backgroundView?.isHidden = true
        return tableView
    }()

    private lazy var label: SmartLabel = {
        let label = SmartLabel()
        label.text = UIConstants.strings.autocompleteEmptyState
        label.font = .footnote12
        label.textColor = .primaryText
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let emptyStateView = UIView()

    private let customAutocompleteSource: CustomAutocompleteSource
    private var domains: [String] { return customAutocompleteSource.getSuggestions() }

    init(customAutocompleteSource: CustomAutocompleteSource) {
        self.customAutocompleteSource = customAutocompleteSource
        super.init(nibName: nil, bundle: nil)

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: UIConstants.strings.edit, style: .plain, target: self, action: #selector(AutocompleteCustomUrlViewController.toggleEditing))
        navigationItem.rightBarButtonItem?.accessibilityIdentifier = "editButton"

        view.addSubview(tableView)
        emptyStateView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.topAnchor.constraint(equalTo: view.topAnchor, constant: UIConstants.layout.autocompleteCustomURLLabelOffset),

            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = UIConstants.strings.autocompleteManageSitesLabel

        tableView.dataSource = self
        tableView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem?.isEnabled = !domains.isEmpty
        tableView.reloadData()
    }

    @objc
    private func toggleEditing() {
        navigationItem.rightBarButtonItem?.title = tableView.isEditing ? UIConstants.strings.edit : UIConstants.strings.done

        tableView.setEditing(!tableView.isEditing, animated: true)

        // Remove adding custom URL section in edit mode
        if tableView.isEditing {
            tableView.deleteRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        } else {
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        }

        navigationItem.setHidesBackButton(tableView.isEditing, animated: true)
        updateEmptyStateView()
        navigationItem.rightBarButtonItem?.isEnabled = tableView.isEditing || !domains.isEmpty
    }

    @objc
    private func updateEmptyStateView() {
        if tableView.isEditing && domains.isEmpty {
            tableView.backgroundView?.animateHidden(false, duration: UIConstants.layout.autocompleteAnimationDuration)
        } else {
            guard !tableView.backgroundView!.isHidden else { return }
            tableView.backgroundView?.animateHidden(true, duration: UIConstants.layout.autocompleteAnimationDuration)
        }
    }

    enum Section: Int, CaseIterable {
        case add
        case list
    }
}

extension AutocompleteCustomUrlViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Section(rawValue: section)
            .map {
                switch $0 {
                case .add:
                    return tableView.isEditing ? 0 : 1
                case .list:
                    return domains.count
                }
            }
        ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        Section(rawValue: indexPath.section)
            .map {
                var cell: UITableViewCell
                switch $0 {
                case .add:
                    cell = UITableViewCell(style: .subtitle, reuseIdentifier: "addCustomDomainCell")
                    cell.textLabel?.text = UIConstants.strings.autocompleteAddCustomUrlWithPlus
                    cell.accessoryType = .disclosureIndicator
                    cell.accessibilityIdentifier = "addCustomDomainCell"
                    cell.selectionStyle = .gray

                case .list:
                    cell = UITableViewCell(style: .subtitle, reuseIdentifier: "domainCell")
                    cell.selectionStyle = .none
                    cell.textLabel?.text = domains[indexPath.row]
                    cell.accessibilityIdentifier = domains[indexPath.row]
                }
                cell.textLabel?.textColor = .primaryText
                return cell
            }
        ?? UITableViewCell()
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        Section(rawValue: indexPath.section) != .add
    }

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        Section(rawValue: indexPath.section) != .add
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if Section(rawValue: indexPath.section) == .add {
            let viewController = AddCustomDomainViewController(autocompleteSource: customAutocompleteSource)
            viewController.delegate = self
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        tableView.isEditing ? .delete : .none
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            _ = customAutocompleteSource.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()

            // We need to wait till after the editing animation when swiping to delete
            // to make sure we're really not in editing mode
            perform(#selector(updateEmptyStateView), with: nil, afterDelay: UIConstants.layout.autocompleteAfterDelayDuration)
        }
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        navigationItem.rightBarButtonItem?.isEnabled = !domains.isEmpty
    }

    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let itemToMove = domains[sourceIndexPath.row]
        _ = customAutocompleteSource.remove(at: sourceIndexPath.row)
        _ = customAutocompleteSource.add(suggestion: itemToMove, atIndex: destinationIndexPath.row)
    }

    /// Disable moving rows between sections.
    ///
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            return sourceIndexPath
        } else {
            return proposedDestinationIndexPath
        }
    }
}

extension AutocompleteCustomUrlViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
}

extension AutocompleteCustomUrlViewController: AddCustomDomainViewControllerDelegate {
    func addCustomDomainViewControllerDidFinish(_ viewController: AddCustomDomainViewController) {
        navigationItem.rightBarButtonItem?.isEnabled = !domains.isEmpty
        tableView.reloadData()
    }
}
