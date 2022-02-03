// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import MozillaAppServices

class ExperimentsViewController: UIViewController {
    private let experimentsView = ExperimentsTableView()
    private let experiments: NimbusApi
    private var availableExperiments: [AvailableExperiment]

    init(experiments: NimbusApi = Experiments.shared) {
        self.experiments = experiments
        self.availableExperiments = experiments.getAvailableExperiments()

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Experiments"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit) { item in
            self.showSettings()
        }

        NotificationCenter.default.addObserver(forName: .nimbusExperimentsApplied, object: nil, queue: .main) { _ in
            self.onExperimentsApplied()
        }
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func loadView() {
        view = experimentsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        experimentsView.delegate = self
        experimentsView.dataSource = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        guard let row = experimentsView.indexPathForSelectedRow else { return }
        experimentsView.deselectRow(at: row, animated: true)
    }

    private func showSettings() {
        let vc = ExperimentsSettingsViewController()
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func onExperimentsApplied() {
        DispatchQueue.main.async {
            self.availableExperiments = self.experiments.getAvailableExperiments()
            self.experimentsView.reloadData()
        }
    }
}

extension ExperimentsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return availableExperiments.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExperimentsTableView.CellIdentifier, for: indexPath)
        let experiment = availableExperiments[indexPath.row]
        let branch = experiments.getExperimentBranch(experimentId: experiment.slug) ?? "Not enrolled"

        cell.textLabel?.text = experiment.userFacingName
        cell.detailTextLabel?.numberOfLines = 3
        cell.detailTextLabel?.text = experiment.userFacingDescription + "\nEnrolled in: \(branch)"
        return cell
    }
}

extension ExperimentsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let experiment = availableExperiments[indexPath.row]
        let vc = ExperimentsBranchesViewController(experiment: experiment)
        navigationController?.pushViewController(vc, animated: true)
    }
}
