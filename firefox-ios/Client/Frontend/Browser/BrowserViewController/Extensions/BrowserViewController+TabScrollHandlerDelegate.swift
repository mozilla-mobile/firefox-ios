// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

extension BrowserViewController: TabScrollHandler.Delegate {
    // TODO: Add bounce effect logic afterwards
    func startAnimatingToolbar(displayState: TabScrollHandler.ToolbarDisplayState) {}
    func showToolbar() {
        overKeyboardContainer.snp.remakeConstraints { make in
            make.bottom.equalTo(bottomContainer.snp.top)
            if !isBottomSearchBar, zoomPageBar != nil {
                make.height.greaterThanOrEqualTo(0)
            } else if !isBottomSearchBar {
                make.height.equalTo(0)
            }
            make.leading.trailing.equalTo(view)
        }

        bottomContainer.snp.remakeConstraints { make in
            make.bottom.equalTo(view.snp.bottom)
            make.leading.trailing.equalTo(view)
        }

        bottomContentStackView.snp.remakeConstraints { remake in
            adjustBottomContentStackView(remake)
        }
    }

    func hideToolbar() {
        bottomContainer.snp.remakeConstraints { make in
            make.top.equalTo(view.snp.bottom)
            make.height.equalTo(0)
            make.leading.trailing.equalTo(view)
        }

        overKeyboardContainer.snp.remakeConstraints { make in
            make.bottom.equalTo(bottomContainer.snp.top)
            make.height.equalTo(0)
            make.leading.trailing.equalTo(view)
        }

        bottomContentStackView.snp.remakeConstraints { remake in
            adjustBottomContentStackView(remake)
        }
    }
}
