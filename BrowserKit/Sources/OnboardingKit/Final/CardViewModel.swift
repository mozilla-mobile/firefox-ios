// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


import SwiftUI

// MARK: – View Model

struct CardViewModel {
    let imageName: String
    let title: String
    let subtitle: String
    let primaryButtonTitle: String
    let secondaryButtonTitle: String
}

// MARK: – Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .foregroundColor(.white)
    }
}

// MARK: – Full‐Screen Wrapper with Aspect‐Constrained Card

struct TrackerProtectionScreen: View {
    let vm: CardViewModel

    var body: some View {
        ZStack {
            // full‐screen gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.orange, Color.red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack {
                // card spans full width minus 16pt margins,
                // height is derived by the 0.8 aspect ratio
                VStack(spacing: 24) {
                    
                    Spacer()
                    
                    Text(vm.title)
                        .font(.title3).fontWeight(.semibold)
                        .multilineTextAlignment(.center)

                    Image(systemName: vm.imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.accentColor)

                    Text(vm.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                    
                    Button(vm.primaryButtonTitle) {
                        // primary action
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .frame(height: 600)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1),
                                radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, 24)

                // “Not Now” at bottom
                Button(vm.secondaryButtonTitle) {
                    // secondary action
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.top, 8)
                .padding(.bottom, 24)
                Spacer()
            }
        }
    }
}

// MARK: – Preview

struct TrackerProtection_Previews: PreviewProvider {
    static let vm = CardViewModel(
        imageName: "shield.fill",
        title: "Get automatic protection from trackers",
        subtitle: "One tap helps stop companies spying on your clicks.",
        primaryButtonTitle: "Set as Default Browser",
        secondaryButtonTitle: "Not Now"
    )

    static var previews: some View {
        TrackerProtectionScreen(vm: vm)
            .preferredColorScheme(.light)
        TrackerProtectionScreen(vm: vm)
            .preferredColorScheme(.dark)
    }
}

import SwiftUI

// MARK: – Model

/// The two possible positions
enum AddressBarPosition: CaseIterable, Identifiable {
    case bottom, top
    var id: Self { self }
    
    var label: String {
        switch self {
        case .bottom: return "Bottom"
        case .top:    return "Top"
        }
    }
}

// MARK: – View Model

final class AddressBarViewModel: ObservableObject {
    let title: String
    let buttonTitle: String
    @Published var selected: AddressBarPosition
    
    init(
        title: String = "Where do you want your address bar?",
        buttonTitle: String = "Continue",
        initialSelection: AddressBarPosition = .bottom
    ) {
        self.title = title
        self.buttonTitle = buttonTitle
        self.selected = initialSelection
    }
}

// MARK: – One Option (phone + capsule + circle)

struct AddressBarOptionView: View {
    let position: AddressBarPosition
    @Binding var selected: AddressBarPosition

    private var isSelected: Bool { selected == position }
    
    var body: some View {
        VStack(spacing: 8) {
            // 1) Phone outline + bar
            ZStack(alignment: position == .bottom ? .bottom : .top) {
                // phone body
                Image(systemName: "iphone")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 120)
                    .foregroundColor(isSelected ? .accentColor : .gray.opacity(0.6))
                
                // the “address bar” as a capsule
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 40, height: 6)
                    .padding(position == .bottom ? .bottom : .top, 16)
            }
            
            // 2) Label
            Text(position.label)
                .font(.caption)
                .foregroundColor(.primary)
            
            // 3) Selection circle
            Image(systemName: isSelected
                  ? "largecircle.fill.circle"
                  : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
        }
        .onTapGesture {
            withAnimation { selected = position }
        }
    }
}


// MARK: – The Card

struct AddressBarChoiceCard: View {
    @ObservedObject var vm: AddressBarViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            // Title
            Text(vm.title)
                .font(.title3).fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            // HStack of two options
            HStack(spacing: 48) {
                ForEach(AddressBarPosition.allCases) { pos in
                    AddressBarOptionView(position: pos, selected: $vm.selected)
                }
            }
            
            // Continue button
            Button(vm.buttonTitle) {
                // handle continue…
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1),
                        radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: – Full Screen Wrapper

struct AddressBarChoiceScreen: View {
    @StateObject private var vm = AddressBarViewModel()
    
    var body: some View {
        ZStack {
            // 1) Gradient background
            LinearGradient(
                gradient: Gradient(colors: [Color.orange, Color.red]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // 2) Centered card, max 60% of screen height
            GeometryReader { geo in
                VStack {
                    Spacer()
                    
                    AddressBarChoiceCard(vm: vm)
                        .frame(
                            width: geo.size.width - 32,
                            height: geo.size.height * 0.6
                        )
                    
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

// MARK: – Preview

struct AddressBarChoice_Previews: PreviewProvider {
    static var previews: some View {
        AddressBarChoiceScreen()
            .preferredColorScheme(.light)
        
        AddressBarChoiceScreen()
            .preferredColorScheme(.dark)
    }
}
