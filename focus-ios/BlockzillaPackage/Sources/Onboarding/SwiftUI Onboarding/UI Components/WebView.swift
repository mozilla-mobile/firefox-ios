// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


import SwiftUI
import WebKit

enum WebViewState {
    case loading
    case loaded
    case error
}

class WebViewModel: ObservableObject {
    @Published var state: WebViewState = .loading
    private var webView: WKWebView?
    var url: URL?

    func setWebView(_ webView: WKWebView, url: URL) {
        self.webView = webView
        self.url = url
    }

    func reload() {
        DispatchQueue.main.async {
            guard let url = self.url else { return }
            self.state = .loading
            self.webView?.stopLoading()
            self.webView?.load(URLRequest(url: url))
        }
    }
}


// WebView for displaying the URL
struct WebView: UIViewRepresentable {
    let url: URL
    @ObservedObject var viewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))

        DispatchQueue.main.async {
            viewModel.setWebView(webView, url: url)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var viewModel: WebViewModel

        init(viewModel: WebViewModel) {
            self.viewModel = viewModel
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.state = .loading
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.viewModel.state = .loaded
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.viewModel.state = .error
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.viewModel.state = .error
            }
        }
    }
}

// Privacy Policy View
struct PrivacyPolicyView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = WebViewModel()
    
    private struct Constants {
        static let buttonPadding: CGFloat = 26
        static let titlePadding: CGFloat = 20
        static let subtitlePadding: CGFloat = 10
    }

    let url: URL
    let doneButtonText: String
    let errorMessage: String
    let retryButtonText: String

    init(
        doneButtonText: String,
        errorMessage: String,
        retryButtonText: String,
        url: URL
    ) {
        self.doneButtonText = doneButtonText
        self.errorMessage = errorMessage
        self.retryButtonText = retryButtonText
        self.url = url
    }

    var body: some View {
        NavigationView {
            ZStack {
                WebView(url: url, viewModel: viewModel)

                if viewModel.state == .loading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.8))
                }

                if viewModel.state == .error {
                    VStack {
                        Image(systemName: "wifi.slash")
                            .resizable()
                            .frame(width: 50, height: 50)
                            .foregroundColor(.gray)
                            .padding()

                        Text(errorMessage)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()

                        Button(action: {
                            viewModel.reload()
                        }) {
                            Text(retryButtonText)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(Constants.buttonPadding)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white.opacity(0.8))
                }
            }
            .navigationBarItems(trailing: Button(doneButtonText) {
                presentationMode.wrappedValue.dismiss()
            })
            .ignoresSafeArea(edges: [.bottom])
        }
    }
}
