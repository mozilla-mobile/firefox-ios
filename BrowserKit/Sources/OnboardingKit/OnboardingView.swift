//// This Source Code Form is subject to the terms of the Mozilla Public
//// License, v. 2.0. If a copy of the MPL was not distributed with this
//// file, You can obtain one at http://mozilla.org/MPL/2.0/
//
//import SwiftUI
//
//struct OnboardingCard: View {
//    var onboardingCardModel: OnboardingCardModel
//    @Binding var selectedSearchBarPosition: SearchBarPosition
//    var onNext: () -> Void
//
//    var body: some View {
//        VStack {
//            if onboardingCardModel.type == .privacy {
//                // Default layout for other types (welcome, search, etc.)
//                VStack(spacing: 16) {
//                    Text(onboardingCardModel.title)
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 16)
//                        .frame(height: 120)
//                        .padding(.top, 40)
//                    
//                    if let imageName = onboardingCardModel.imageName {
//                        Image(imageName)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 160) // Adjust as needed
//                            .padding(.horizontal, 20)
//                    }
//                    
//                    if let description = onboardingCardModel.description {
//                        Text(description)
//                            .font(.body)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal, 16)
//                    }
//                    
//                }
//            } else if onboardingCardModel.type == .welcome {
//                VStack(spacing: 16) {
//                    if let imageName = onboardingCardModel.imageName {
//                        Image(imageName)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 74)
//                            .padding(.top, 40)
//                    }
//
//                    Text(onboardingCardModel.title)
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 16)
//
//                    if let description = onboardingCardModel.description {
//                        Text(description)
//                            .font(.body)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal, 16)
//                    }
//                    Spacer()
//                }
//            } else if onboardingCardModel.type == .searchBarPosition {
//                VStack(spacing: 16) {
//                    Text(onboardingCardModel.title)
//                        .font(.title)
//                        .fontWeight(.bold)
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 16)
//                        .frame(height: 120)
//                        .padding(.top, 40)
//                    
//                    SearchBarSelectionView(selectedPosition: $selectedSearchBarPosition)
//                }
//            }
//
//            Spacer()
//
//            if !onboardingCardModel.additionalText.isEmpty {
//                VStack(alignment: .center, spacing: 6) {
//                    ForEach(onboardingCardModel.additionalText) { textModel in
//                        Group {
//                            Text(textModel.text)
//                                .font(.footnote)
//                                .foregroundColor(.gray)
//                            +
//                            Text(textModel.linkText)
//                                .font(.footnote)
//                                .foregroundColor(.blue)
//                        }
//                        .multilineTextAlignment(.center)
//                        .padding(.horizontal, 20)
//                        .frame(maxWidth: .infinity, alignment: .center)
//                        .fixedSize(horizontal: false, vertical: true)
//                    }
//                }
//                .padding(.bottom, 10)
//            }
//
//            Button(action: {
//                onNext()
//            }) {
//                Text(onboardingCardModel.buttonTitle)
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
//        .frame(maxWidth: .infinity)
//        .padding()
//        .background(.white)
//        .cornerRadius(20)
//        .shadow(radius: 10)
//    }
//}
//
//struct SearchBarSelectionView: View {
//    @Binding var selectedPosition: SearchBarPosition
//    
//    var body: some View {
//        VStack(spacing: 16) {
//            HStack(spacing: 20) {
//                SearchBarOptionView(position: .bottom, selectedPosition: $selectedPosition)
//                SearchBarOptionView(position: .top, selectedPosition: $selectedPosition)
//            }
//            .padding(.horizontal, 20)
//        }
//    }
//}
//
//struct SearchBarOptionView: View {
//    var position: SearchBarPosition
//    @Binding var selectedPosition: SearchBarPosition
//    
//    var body: some View {
//        VStack {
//            Image(systemName: position == .bottom ? "rectangle.bottomthird.inset.filled" : "rectangle.topthird.inset.filled")
//                .resizable()
//                .scaledToFit()
//                .frame(height: 160)
//                .foregroundColor(selectedPosition == position ? .blue : .gray)
//
//            Text(position.rawValue.capitalized)
//                .font(.body)
//
//            Button(action: {
//                selectedPosition = position
//            }) {
//                Circle()
//                    .fill(selectedPosition == position ? Color.blue : Color.gray.opacity(0.3))
//                    .frame(width: 24, height: 24)
//                    .overlay(
//                        Circle()
//                            .stroke(Color.blue, lineWidth: selectedPosition == position ? 2 : 1)
//                    )
//            }
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//
//import SwiftUI
//
//struct OnboardingCardModel {
//    var type: OnboardingCardType
//    var title: String
//    var description: String?
//    var imageName: String?
//    var buttonTitle: String
//    var additionalText: [OnboardingTextModel]
//}
//
//struct OnboardingTextModel: Identifiable {
//    let id = UUID()
//    var text: String
//    var linkText: String
//    var linkURL: URL?
//}
//
//enum OnboardingCardType {
//    case welcome
//    case privacy
//    case searchBarPosition
//}
//
//enum SearchBarPosition: String {
//    case bottom = "Bottom"
//    case top = "Top"
//}
//
//
//struct OnboardingView: View {
//    var onComplete: () -> Void
//    
//    let onboardingCards: [OnboardingCardModel] = [
//        OnboardingCardModel(
//            type: .welcome,
//            title: "Say hello to Firefox",
//            description: "Welcome to a web you can trust",
//            imageName: "firefox_icon",
//            buttonTitle: "Agree and Continue",
//            additionalText: [
//                OnboardingTextModel(text: "By continuing, you agree to the ", linkText: "Firefox Terms of Use", linkURL: URL(string: "https://www.mozilla.org/en-US/about/legal/terms/")),
//                OnboardingTextModel(text: "Firefox cares about your privacy. Read more in our ", linkText: "Privacy Notice", linkURL: URL(string: "https://www.mozilla.org/en-US/privacy/")),
//                OnboardingTextModel(text: "To help improve the browser, Firefox sends diagnostic and interaction data to Mozilla. ", linkText: "Manage settings", linkURL: URL(string: "https://support.mozilla.org/"))
//            ]
//        ),
//        OnboardingCardModel(
//            type: .privacy,
//            title: "Goodbye trackers.\nHello privacy.",
//            description: "One choice protects you everywhere you go on the web. You can always change it later.",
//            imageName: "goodbye_trackers",
//            buttonTitle: "Set as Default Browser",
//            additionalText: []
//        ),
//        OnboardingCardModel(
//            type: .searchBarPosition,
//            title: "Where do you want your search bar?",
//            description: nil,
//            imageName: nil,
//            buttonTitle: "Continue",
//            additionalText: []
//        )
//    ]
//    
//    @State private var currentPage = 0
//    @State private var selectedSearchBarPosition: SearchBarPosition = .bottom
//    
//    var body: some View {
//        ZStack {
//            MilkyWayMetalView()
//                .edgesIgnoringSafeArea(.all)
//            TabView(selection: $currentPage) {
//                ForEach(0..<onboardingCards.count, id: \.self) { index in
//                    let card = onboardingCards[index]
//
//                    VStack {
//                        OnboardingCard(
//                            onboardingCardModel: card,
//                            selectedSearchBarPosition: $selectedSearchBarPosition,
//                            onNext: {
//                                if index < onboardingCards.count - 1 {
//                                    withAnimation {
//                                        currentPage += 1
//                                    }
//                                } else {
//                                    onComplete()
//                                }
//                            }
//                        )
//                        .padding(.top, 40)
//                        .padding(.horizontal, 20)
//                        .padding(.bottom, 110)
//                    }
//                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
//                    .tag(index)
//                }
//            }
//            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//        }
//    }
//}
//
//#Preview {
//    OnboardingView(onComplete: {})
//}
