// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI

@available(iOS 14.0, *)
public struct OnboardingView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        stylePageControl()
    }

    public var body: some View {
        TabView(selection: $viewModel.activeScreen) {
            GetStartedOnboardingView(viewModel: viewModel)
                .tag(Screen.getStarted)
            DefaultBrowserOnboardingView(viewModel: viewModel)
                .tag(Screen.default)
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .ignoresSafeArea()
    }

    func stylePageControl() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .systemBlue
        UIPageControl.appearance().pageIndicatorTintColor = .systemGray
    }
}

@available(iOS 14.0, *)
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(viewModel: .dummy)
    }
}
