//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//
//// OnboardingUI.swift
//
//import SwiftUI
//import UIKit
//
//// MARK: - Models & Protocols
//
//public enum OnboardingButtonAction {
//    case next, cancel, done
//}
//
//public struct OnboardingInstructionsPopupInfoModel {}
//
//public struct OnboardingLinkInfoModel {
//    public let title: String
//    public init(title: String) {
//        self.title = title
//    }
//}
//
//public struct OnboardingButtonInfoModel {
//    public let title: String
//    public let action: OnboardingButtonAction
//    public init(title: String, action: OnboardingButtonAction) {
//        self.title = title
//        self.action = action
//    }
//}
//
//public struct OnboardingButtons {
//    public let primary: OnboardingButtonInfoModel
//    public let secondary: OnboardingButtonInfoModel?
//    public init(
//        primary: OnboardingButtonInfoModel,
//        secondary: OnboardingButtonInfoModel? = nil
//    ) {
//        self.primary = primary
//        self.secondary = secondary
//    }
//}
//
//public struct OnboardingMultipleChoiceButtonModel: Equatable, Hashable {
//    public let title: String
//    public let action: OnboardingMultipleChoiceAction
//    public let imageID: String
//    public init(
//        title: String,
//        action: OnboardingMultipleChoiceAction,
//        imageID: String
//    ) {
//        self.title = title
//        self.action = action
//        self.imageID = imageID
//    }
//}
//
//public protocol OnboardingCardInfoModelProtocol {
//    var cardType: OnboardingCardType { get set }
//    var name: String { get set }
//    var order: Int { get set }
//    var title: String { get set }
//    var body: String { get set }
//    var instructionsPopup: OnboardingInstructionsPopupInfoModel? { get set }
//    var link: OnboardingLinkInfoModel? { get set }
//    var buttons: OnboardingButtons { get set }
//    var multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel] { get set }
//    var onboardingType: OnboardingType { get set }
//    var a11yIdRoot: String { get set }
//    var imageID: String { get set }
//    var image: UIImage? { get }
//    
//    init(
//        cardType: OnboardingCardType,
//        name: String,
//        order: Int,
//        title: String,
//        body: String,
//        link: OnboardingLinkInfoModel?,
//        buttons: OnboardingButtons,
//        multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel],
//        onboardingType: OnboardingType,
//        a11yIdRoot: String,
//        imageID: String,
//        instructionsPopup: OnboardingInstructionsPopupInfoModel?
//    )
//}
//

//// MARK: - Top-Level Dispatcher
//







//
//// MARK: –– Onboarding Flow
//
////struct OnboardingView: View {
////    var onComplete: () -> Void
////
////    // grab our dummy data
////    private let feature = OnboardingFrameworkFeature.previewAll
////    @State private var currentPage = 0
//////    @State private var selectedSearchBarPosition: SearchBarPosition = .bottom
////
////    // sort cards by `order`
////    private var sortedCards: [NimbusOnboardingCardData] {
////        feature.cards.values
////            .sorted { $0.order < $1.order }
////    }
////
////    var body: some View {
////        ZStack {
////            MilkyWayMetalView()
////                .edgesIgnoringSafeArea(.all)
////
////            TabView(selection: $currentPage) {
////                ForEach(Array(sortedCards.enumerated()), id: \.element.id) { idx, card in
////                    OnboardingCard(
////                        cardData: card,
////                        selectedSearchBarPosition: $selectedSearchBarPosition
////                    ) {
////                        withAnimation {
////                            if idx < sortedCards.count - 1 {
////                                currentPage += 1
////                            } else {
////                                onComplete()
////                            }
////                        }
////                    }
////                    .padding(.top, 40)
////                    .padding(.horizontal, 20)
////                    .padding(.bottom, 110)
////                    .tag(idx)
////                }
////            }
////            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
////        }
////    }
////}
//
//// MARK: –– Preview
//
////struct OnboardingView_Previews: PreviewProvider {
////    static var previews: some View {
////        OnboardingView(onComplete: { print("Done!") })
////    }
////}
//
//enum SearchBarPosition: String {
//    case bottom = "Bottom"
//    case top = "Top"
//}
