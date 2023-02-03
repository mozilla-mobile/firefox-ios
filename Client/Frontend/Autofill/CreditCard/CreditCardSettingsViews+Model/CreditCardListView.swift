// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Storage

class CreditCardListViewModel: ObservableObject {
    @Published var creditCards: [CreditCard] = [CreditCard]()

    @Published var toggleState = true {
        didSet(val) {
            print("val \(val)")
        }
    }

    init() {}

    init(creditCards: [CreditCard]) {
        self.creditCards = creditCards
    }

    func cardTapped(creditCard: CreditCard) {
        print(creditCard)
    }
}

struct CreditCardListView: View {
    @ObservedObject var viewModel: CreditCardListViewModel = CreditCardListViewModel(creditCards: [CreditCard]())

    init() {
        UITableView.appearance().backgroundColor = .clear // tableview background
        UITableViewCell.appearance().backgroundColor = .clear // cell background
    }

    init(viewModel: CreditCardListViewModel) {
        self.init()
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            CreditCardAutofillToggle(viewModel: viewModel)
                .edgesIgnoringSafeArea(.top)
                .padding(.top, 20)

            Text("Saved Cards")
                .font(.system(size: 15))
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity,
                       alignment: .leading)
                .padding(.leading, 20)
                .padding(.top, 25)
                .padding(.bottom, 8)

            let creditCards = viewModel.creditCards
            if #available(iOS 14.0, *) {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(creditCards, id: \.self) { creditCard in
                            VStack(spacing: 0) {

                                Button {
                                    print("somecode")
                                } label: {
                                    CreditCardItemRow(item: creditCard, ux: CreditCardItemRowUX(titleTextColor: .black, subTextColor: .gray, separatorColor: .gray))
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            print("Tapped")
                                            viewModel.cardTapped(creditCard: creditCard)
                                        }
                                }
                                .frame(maxWidth: .infinity)
                                .buttonStyle(PlainButtonStyle())

                            }
                        }
                    }
                }
            }

        }
        .background(Color(UIColor.clear))

    }

    func temp() -> some View {
        if !viewModel.creditCards.isEmpty {
            viewModel.creditCards.remove(at: 0)
        }
        return EmptyView()
    }
}
