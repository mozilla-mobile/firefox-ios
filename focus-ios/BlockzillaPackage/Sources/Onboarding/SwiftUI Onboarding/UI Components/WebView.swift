// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


import SwiftUI
import WebKit

// WebView for displaying the URL
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool // Binding to track loading state

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator // Set the coordinator as the navigation delegate
        webView.load(URLRequest(url: url)) // Load the URL once when the WebView is created
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Don't reload the URL every time updateUIView is called
        // Only load the URL once when the view is created
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(isLoading: $isLoading)
    }

    // Coordinator class to act as WKWebView's delegate
    class Coordinator: NSObject, WKNavigationDelegate {
        @Binding var isLoading: Bool

        init(isLoading: Binding<Bool>) {
            _isLoading = isLoading
        }

        // When navigation starts, set isLoading to true
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading = true
        }

        // When navigation finishes, set isLoading to false
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
        }

        // Handle errors and set isLoading to false
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            isLoading = false
        }
    }
}

// Privacy Policy View
struct PrivacyPolicyView: View {
    @State private var url: URL
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false

    let doneButtonText: String
    
    init(
        doneButtonText: String,
        url: URL
    ) {
        self.doneButtonText = doneButtonText
        _url = State(initialValue: url)
    }

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                }
                WebView(url: url, isLoading: $isLoading)
                    .navigationBarItems(trailing: Button(doneButtonText) {
                        presentationMode.wrappedValue.dismiss()
                    })
            }
            .ignoresSafeArea(edges: [.bottom])
        }
    }
}
