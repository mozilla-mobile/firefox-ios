// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class RemoteSettingsOptionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private var collections: [ServerCollection] = []
    private var remoteSettingsUtil = RemoteSettingsUtil(bucket: .defaultBucket, collection: .searchTelemetry)
    private var logger: Logger
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: OneLineTableViewCell.self)
        return tableView
    }()

    init(logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        fetchCollections(bucketID: Remotebucket.defaultBucket.rawValue)
    }

    private func setupNavigationBar() {
        let settingsButton = UIBarButtonItem(image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.settings),
                                             style: .plain,
                                             target: self,
                                             action: #selector(settingsButtonTapped))
        navigationItem.rightBarButtonItem = settingsButton
    }

    @objc func settingsButtonTapped() {
        let alertController = UIAlertController(title: "Settings", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Enter Bucket ID (default: main)"
        }
        
        let fetchAction = UIAlertAction(title: "Fetch", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let bucketID = alertController.textFields?.first?.text?.isEmpty ?? true ? "main" : alertController.textFields?.first?.text!
            self.fetchCollections(bucketID: bucketID ?? Remotebucket.defaultBucket.rawValue)
        }
        
        let resetAction = UIAlertAction(title: "Reset", style: .default) { [weak self] _ in
            self?.fetchCollections(bucketID: Remotebucket.defaultBucket.rawValue)
        }
        
        alertController.addAction(fetchAction)
        alertController.addAction(resetAction)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        present(alertController, animated: true, completion: nil)
    }

    private func setupTableView() {
        view.addSubview(tableView)
    }

    func fetchCollections(bucketID: String) {
        print(remoteSettingsUtil.loadPasswordRules()?.first?.domain ?? "")
        remoteSettingsUtil.fetchCollections(for: bucketID) { [weak self] collections in
            DispatchQueue.main.async {
                self?.collections = collections ?? []
                self?.tableView.reloadData()
            }
        }
    }

RemoteSettingsOptions/RemoteSettingsOptionViewController.swift
    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collections.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OneLineTableViewCell.cellIdentifier,
                                                       for: indexPath) as? OneLineTableViewCell
        else {
            return UITableViewCell()
        }
        let collection = collections[indexPath.row]
        let viewModel = OneLineTableViewCellViewModel(
            title: collection.id,
            leftImageView: nil,
            accessoryView: nil,
            accessoryType: .disclosureIndicator
        )
        cell.configure(viewModel: viewModel)
        return cell
    }

    // MARK: - UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let collection = collections[indexPath.row]
        fetchRecords(for: collection)
    }

    private func fetchRecords(for collection: ServerCollection) {
        remoteSettingsUtil.updateAndFetchRecords(for: .searchTelemetry) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    let recordsString = self.prettyPrint(records) ?? "No records"
                    let detailVC = RecordDetailViewController(recordDetails: recordsString)
                    self.navigationController?.pushViewController(detailVC, animated: true)
                case .failure(let error):
                    let errorString = "Failed to fetch records: \(error.localizedDescription)"
                    let detailVC = RecordDetailViewController(recordDetails: errorString)
                    self.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
        }
    }
    
    // MARK: Helper

    private func fetchCollections(bucketID: String) {
        remoteSettingsUtil.fetchCollections(for: bucketID) { [weak self] collections in
            DispatchQueue.main.async {
                self?.collections = collections ?? []
                self?.tableView.reloadData()
            }
        }
    }

    private func prettyPrint<T: Codable>(_ value: [T]) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let data = try encoder.encode(value)
            if var jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {

                for (index, var item) in jsonArray.enumerated() {
                    // Check if "fields aka RsJsonObject" is a string and parse it as JSON if possible
                    if let fieldsString = item["fields"] as? String,
                       let fieldsData = fieldsString.data(using: .utf8),
                       let fieldsJSON = try? JSONSerialization.jsonObject(with: fieldsData, options: []) {
                        item["fields"] = fieldsJSON
                    }
                    jsonArray[index] = item
                }

                let cleanedData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
                return String(data: cleanedData, encoding: .utf8)
            }
        } catch {
            logger.log("Failed to encode JSON",
                       level: .warning,
                       category: .remoteSettings,
                       description: "\(error)")
            return nil
        }
        return nil
    }
}
