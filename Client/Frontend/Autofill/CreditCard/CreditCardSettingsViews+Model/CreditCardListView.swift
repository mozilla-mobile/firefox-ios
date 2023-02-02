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
            
            /*
            List(4..<creditCards.count, id: \.self) {index in
                Text("\(creditCards[index].ccName)")
                    .listRowBackground(Color.pink)
//                    .background(Color(UIColor.Photon.Yellow30))

                CreditCardItemRow(item: creditCards[index])
                    .listRowBackground(Color.green)
                    .onTapGesture {
                        print("Tapped")
                        viewModel.cardTapped(creditCard: creditCards[index])
                    }

            }
//            .onAppear {
//                // Set the default to clear
//                UITableView.appearance().backgroundColor = .yellow
//            }
//            .foregroundColor(.pink)
//            .listSeparatorStyleNone()
            .background(Color(UIColor.Photon.Blue05))
            .frame(maxWidth: .infinity)
            .listStyle(.plain)
             */
            
            
            
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
        .background(Color(UIColor.clear))

    }
    
    func temp() -> some View {
        if !viewModel.creditCards.isEmpty {
            viewModel.creditCards.remove(at: 0)
        }
        
        return EmptyView()
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
