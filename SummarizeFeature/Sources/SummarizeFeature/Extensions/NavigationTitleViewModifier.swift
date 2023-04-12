//
//  NavigationTitleViewModifier.swift
//

import SwiftUI

fileprivate struct NavigationTitleViewModifier<S: StringProtocol>: ViewModifier {
    var title: S
    
    func body(content: Content) -> some View {
        content.navigationBarTitle(title)
    }
}

extension View {
    @_disfavoredOverload
    @ViewBuilder
    public func navigationTitle<S>(_ title: S) -> some View where S : StringProtocol {
        self.modifier(NavigationTitleViewModifier(title: title))
    }
}
