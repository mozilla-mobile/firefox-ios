// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Combine

public class ReactiveSwitch: UISwitch {
    @Published public var isOnPublished: Bool

    public init(isOnPublished: Bool) {
        self.isOnPublished = isOnPublished
        super.init(frame: .zero)
        self.setupPublisher()
    }

    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        fatalError("use `init(isOnPublished: Bool)` instead")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("use `init(isOnPublished: Bool)` instead")
    }

    private func setupPublisher() {
        self.addTarget(self, action: #selector(switchChanged), for: .valueChanged)

        self.$isOnPublished
            .removeDuplicates()
            .sink { [weak self] isOn in
                self?.setOn(isOn, animated: true)
            }
            .store(in: &cancellables)
    }

    @objc func switchChanged(_ sender: UISwitch) {
        self.isOnPublished = sender.isOn
    }
}
