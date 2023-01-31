// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI

struct NoSeparatorList<Data, ID, Content>: View where Data: RandomAccessCollection,
                                                      ID: Hashable,
                                                      Content: View {

    let data: Data
    let id: KeyPath<Data.Element, ID>
    let content: (Data.Element) -> Content

    public init(_ data: Data,
              id: KeyPath<Data.Element, ID>,
              @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = data
        self.id = id
        self.content = content
    }

  var body: some View {
    if #available(iOS 15.0, *) {
        List(data, id: id) { item in
            content(item)
                .listRowSeparator(.hidden)
        }
    } else if #available(iOS 14.0, *) {
        ScrollView {
            LazyVStack {
                ForEach(data, id: id, content: content)
            }
        }
    } else {
        List(data, id: id, rowContent: content)
            .onAppear {
                UITableView.appearance().separatorStyle = .none
                UITableView.appearance().backgroundColor = .green
                UITableView.appearance().rowHeight = 240
            }.onDisappear {
                UITableView.appearance().separatorStyle = .singleLine
                UITableView.appearance().backgroundColor = .green
                UITableView.appearance().rowHeight = 240
            }
    }
  }
}

extension List {
    @ViewBuilder func noSeparators() -> some View {
//        #if swift(>=5.3) // Xcode 12
        if #available(iOS 14.0, *) { // iOS 14
            self
            .accentColor(Color.secondary)
            .listStyle(SidebarListStyle())
            .onAppear {
                UITableView.appearance().backgroundColor = UIColor.systemBackground
            }
        } else { // iOS 13
            self
                        .listStyle(PlainListStyle())
            .onAppear {
                UITableView.appearance().separatorStyle = .none
            }
        }
//        #else // Xcode 11.5
//        self
//                .listStyle(PlainListStyle())
//        .onAppear {
//            UITableView.appearance().separatorStyle = .none
//        }
//        #endif
    }
}
