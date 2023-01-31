// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Storage

//struct CreditCard {
//    var ccName: String
//    var ccNumber: String
//    var imageName: String
//    var expires: String
//    var last4: String
//    var ccType: String
//}

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
    @ObservedObject var viewModel: CreditCardListViewModel
    init(viewModel: CreditCardListViewModel) {
        self.viewModel = viewModel
        UITableView.appearance().backgroundColor = .yellow
        UITableView.appearance().tintColor = .red
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
            NoSeparatorList(4..<creditCards.count, id: \.self) {index in
                CreditCardItemRow(item: creditCards[index])
                    .listRowBackground(Color.green)
                    .onTapGesture {
                        print("Tapped")
                        viewModel.cardTapped(creditCard: creditCards[index])
                    }
            }
            .onAppear {
                // Set the default to clear
                UITableView.appearance().backgroundColor = .yellow
            }
//            .listSeparatorStyleNone()
            .background(Color(UIColor.Photon.Blue05))
            .frame(maxWidth: .infinity)
            .listStyle(.plain)
            
            
            
//            .onAppear {
//                UITableView.appearance().separatorStyle = .none
//                UITableView.appearance().style = .plain
//            }.onDisappear {
//                UITableView.appearance().separatorStyle = .singleLine
//            }
            
//            .listRowInsets(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
//            .onAppear() {
//                UITableView.appearance().separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 50)
//            }
//            .listStyle(InsetGroupedListStyle())
//            .scrollContentBackground(.hidden)
        }
//        .background(.green)
    }
}

//struct CreditCardListView_Previews: PreviewProvider {
//    static let cardList: [CreditCard] = [
//        CreditCard(guid: "1", ccName: "Allen Burges", ccNumberEnc: "1234567891234567", ccNumberLast4: "4567", ccExpMonth: 1234567, ccExpYear: 2023, ccType: "VISA", timeCreated: 1234678, timeLastUsed: nil, timeLastModified: 123123, timesUsed: 123123),
//
//        CreditCard(guid: "2", ccName: "Macky Otter", ccNumberEnc: "0987654323456789", ccNumberLast4: "6789", ccExpMonth: 1234567, ccExpYear: 2023, ccType: "MASTERCARD", timeCreated: 1234678, timeLastUsed: nil, timeLastModified: 123123, timesUsed: 123123)
//    ]
//
//    static var previews: some View {
//        let vm = CreditCardListViewModel(creditCards: cardList)
//        CreditCardListView(viewModel: vm)
//    }
//}

//public struct ListSeparatorStyleNoneModifier: ViewModifier {
//    public func body(content: Content) -> some View {
//        content.onAppear {
//            UITableView.appearance().separatorStyle = .none
//        }.onDisappear {
//            UITableView.appearance().separatorStyle = .singleLine
//        }
//    }
//}
//
//extension View {
//    public func listSeparatorStyleNone() -> some View {
//        modifier(ListSeparatorStyleNoneModifier())
//    }
//}
