// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import MozillaAppServices

class ExperimentsBranchesViewController: UIViewController {
    private let experiment: AvailableExperiment
    private let experimentsBranchesView = ExperimentsTableView()

    init(experiment: AvailableExperiment) {
        self.experiment = experiment
        super.init(nibName: nil, bundle: nil)
        navigationItem.title = experiment.userFacingName
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = experimentsBranchesView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        experimentsBranchesView.delegate = self
        experimentsBranchesView.dataSource = self
    }
}

extension ExperimentsBranchesViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return experiment.branches.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ExperimentsTableView.CellIdentifier, for: indexPath)
        let branch = experiment.branches[indexPath.row]
        let optedIn = Experiments.shared.getExperimentBranch(experimentId: experiment.slug) == branch.slug

        cell.textLabel?.text = branch.slug
        cell.accessoryType = optedIn ? .checkmark : .none
        return cell
    }
}

extension ExperimentsBranchesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let branch = experiment.branches[indexPath.row]
        if Experiments.shared.getExperimentBranch(experimentId: experiment.slug) != branch.slug {
            Experiments.shared.optIn(experiment.slug, branch: branch.slug)
        } else {
            Experiments.shared.optOut(experiment.slug)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            tableView.reloadData()
        }
    }
}
