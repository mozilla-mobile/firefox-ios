//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//
//import SwiftUI
//
//// MARK: –– Reusable Card View
//
//enum SearchBarPosition: String {
//    case bottom = "Bottom"
//    case top = "Top"
//}
//
//struct OnboardingCard: View {
//    let cardData: NimbusOnboardingCardData
//    @Binding var selectedSearchBarPosition: SearchBarPosition
//    var onNext: () -> Void
//
//    var body: some View {
//        VStack(spacing: 0) {  
//            VStack(spacing: 16) {
//                Text(cardData.title)
//                    .font(.title)
//                    .fontWeight(.bold)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal, 16)
//                    .frame(height: 120)
//                    .padding(.top, 40)
//                
//                if let uiImage = UIImage(named: cardData.image.rawValue) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 160) // Adjust as needed
//                        .padding(.horizontal, 20)
//                }
//                
//                Text(cardData.body)
//                    .font(.body)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal, 16)
//                
//            }
//
//            Spacer()
//
//            // Multiple-choice buttons, if any
//            if !cardData.multipleChoiceButtons.isEmpty {
//                VStack(spacing: 12) {
//                    ForEach(cardData.multipleChoiceButtons, id: \.title) { choice in
//                        Button(action: {
//                            // here you’d hook into `choice.action`
//                            onNext()
//                        }) {
//                            HStack {
//                                Image(choice.image.rawValue)
//                                    .resizable()
//                                    .frame(width: 32, height: 32)
//                                Text(choice.title)
//                                    .font(.headline)
//                                Spacer()
//                            }
//                            .padding()
//                            .background(RoundedRectangle(cornerRadius: 8).stroke())
//                        }
//                    }
//                }
//                .padding(.horizontal, 20)
//                .padding(.bottom, 20)
//            }
//
//            // Primary button
//            Button(action: onNext) {
//                Text(cardData.buttons.primary.title)
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .frame(maxWidth: .infinity)
//                    .padding(.vertical, 14)
//                    .background(Color.blue)
//                    .cornerRadius(10)
//            }
//            .padding(.horizontal, 20)
//            .padding(.bottom, 20)
//        }
//        .background(Color.white)
//        .cornerRadius(20)
//        .shadow(radius: 8)
//        .padding(.horizontal, 16)
//    }
//}
//
//// MARK: –– Onboarding Flow
//
//struct OnboardingView: View {
//    var onComplete: () -> Void
//
//    // grab our dummy data
//    private let feature = OnboardingFrameworkFeature.previewAll
//    @State private var currentPage = 0
//    @State private var selectedSearchBarPosition: SearchBarPosition = .bottom
//
//    // sort cards by `order`
//    private var sortedCards: [NimbusOnboardingCardData] {
//        feature.cards.values
//            .sorted { $0.order < $1.order }
//    }
//
//    var body: some View {
//        ZStack {
//            MilkyWayMetalView()
//                .edgesIgnoringSafeArea(.all)
//
//            TabView(selection: $currentPage) {
//                ForEach(Array(sortedCards.enumerated()), id: \.element.id) { idx, card in
//                    OnboardingCard(
//                        cardData: card,
//                        selectedSearchBarPosition: $selectedSearchBarPosition
//                    ) {
//                        withAnimation {
//                            if idx < sortedCards.count - 1 {
//                                currentPage += 1
//                            } else {
//                                onComplete()
//                            }
//                        }
//                    }
//                    .padding(.top, 40)
//                    .padding(.horizontal, 20)
//                    .padding(.bottom, 110)
//                    .tag(idx)
//                }
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//        }
//    }
//}
//
//// MARK: –– Preview
//
//struct OnboardingView_Previews: PreviewProvider {
//    static var previews: some View {
//        OnboardingView(onComplete: { print("Done!") })
//    }
//}
