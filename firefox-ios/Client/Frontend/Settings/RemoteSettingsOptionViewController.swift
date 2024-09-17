// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class RemoteSettingsOptionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: OneLineTableViewCell.self)
        return tableView
    }()
    private var collections: [ServerCollection] = []
    private var remoteSettingsUtil = RemoteSettingsUtil(bucket: .defaultBucket, collection: .searchTelemetry)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupTableView()
        fetchCollections(bucketID: Remotebucket.defaultBucket.rawValue)
    }

    func setupNavigationBar() {
        let settingsButton = UIBarButtonItem(image: UIImage(systemName: "gearshape"),
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

    func setupTableView() {
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

    func fetchRecords(for collection: ServerCollection) {
        remoteSettingsUtil.updateAndFetchRecords(for: .searchTelemetry) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let records):
                    let recordsString = self.remoteSettingsUtil.prettyPrint(records) ?? "No records"
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
}

class RecordDetailViewController: UIViewController {
    var recordDetails: String
    var textView: UITextView = .build { textViewVal in
        textViewVal.isEditable = false
    }
    
    init(recordDetails: String) {
        self.recordDetails = recordDetails
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
    }

    func setupTextView() {
        textView.text = recordDetails
        view.addSubview(textView)
    }
}
