// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import MozillaAppServices

class ExperimentsSettingsViewController: UIViewController {
    private let experiments: NimbusApi
    private let experimentsView = ExperimentsSettingsView()
    private var localExperimentsData = Experiments.getLocalExperimentData() ?? ""

    init(experiments: NimbusApi = Experiments.shared) {
        self.experiments = experiments

        super.init(nibName: nil, bundle: nil)
        navigationItem.title = "Experiments Settings"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = experimentsView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        experimentsView.customExperimentDataTextView.delegate = self
        experimentsView.customRemoteSettingsTextField.addTarget(self, action: #selector(updateState), for: .editingChanged)
        experimentsView.reloadButton.addTarget(self, action: #selector(loadRemoteExperiments), for: .touchUpInside)
        experimentsView.updateButton.addTarget(self, action: #selector(tappedUpdate), for: .touchUpInside)
        experimentsView.usePreviewToggle.addTarget(self, action: #selector(usePreviewToggleTapped), for: .valueChanged)
        updateState()
    }

    @objc private func updateState() {
        experimentsView.reloadButton.isEnabled = !(experimentsView.customRemoteSettingsTextField.text?.isEmpty ?? true)
        experimentsView.customExperimentDataTextView.text = localExperimentsData
        experimentsView.usePreviewToggle.setOn(Experiments.usePreviewCollection(), animated: false)

        let dataDidChange = experimentsView.customExperimentDataTextView.text != localExperimentsData
        experimentsView.updateButton.setTitle(dataDidChange ? "Update" : "Reset", for: .normal)
    }

    @objc private func tappedUpdate(sender: AnyObject) {
        let dataDidChange = experimentsView.customExperimentDataTextView.text != localExperimentsData

        if !dataDidChange {
            Experiments.setLocalExperimentData(payload: nil)
            localExperimentsData = ""
            experiments.fetchExperiments()
        } else {
            let newData = experimentsView.customExperimentDataTextView.text!
            Experiments.setLocalExperimentData(payload: newData)
            experiments.setExperimentsLocally(newData)
            localExperimentsData = newData
        }

        updateState()
        applyPendingExperiments()
    }

    @objc private func loadRemoteExperiments(sender: AnyObject) {
        guard
            let text = experimentsView.customRemoteSettingsTextField.text,
            let url = URL(string: text),
            let data = try? String(contentsOf: url)
            else { return }

        localExperimentsData = data
        Experiments.setLocalExperimentData(payload: data)
        experiments.setExperimentsLocally(data)
        applyPendingExperiments()
        updateState()
    }

    @objc private func usePreviewToggleTapped(sender: UISwitch) {
        Experiments.setUsePreviewCollection(enabled: sender.isOn)
    }

    // Tiny hack to fix the race condition when setting new experiments and navigating back
    // to the experiments screen.
    private func applyPendingExperiments() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.experiments.applyPendingExperiments()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                NotificationCenter.default.post(name: .nimbusExperimentsApplied, object: nil)
            }
        }
    }
}


extension ExperimentsSettingsViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateState()
    }
}
