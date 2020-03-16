//
//  WebViewController.swift
//  WebView Demo for iOS Swift
//
//  Copyright (c) 2015 AgileBits Inc. All rights reserved.
//

import UIKit
import OnePasswordExtension

class WebViewController: UIViewController, UISearchBarDelegate, WKNavigationDelegate {

	@IBOutlet weak var onepasswordFillButton: UIButton!
	@IBOutlet weak var webViewContainer: UIView!
	@IBOutlet weak var searchBar: UISearchBar!
	var webView: WKWebView!

	override func viewDidLoad() {
		super.viewDidLoad()
		onepasswordFillButton.isHidden = (false == OnePasswordExtension.shared().isAppExtensionAvailable())

		let configuration = WKWebViewConfiguration()
		
		webView = WKWebView(frame: webViewContainer.bounds, configuration: configuration)
		webView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
		webView.navigationDelegate = self
		webViewContainer.addSubview(webView)

		guard let htmlFilePath = Bundle.main.path(forResource: "welcome", ofType: "html") else {
			return
		}
		
		var htmlString: String?
		do {
			htmlString = try String(contentsOfFile: htmlFilePath, encoding: .utf8)
		}
		catch {
			print("Failed to obtain the html string from file \(htmlFilePath) with error: <\(String(describing: error))>")
		}
		
		if let htmlString = htmlString {
			webView.loadHTMLString(htmlString, baseURL: URL(string: "https://agilebits.com"))
		}
	}

	@IBAction func fillUsing1Password(_ sender: AnyObject) {
        OnePasswordExtension.shared().fillItem(intoWebView: webView as Any, for: self, sender: sender, showOnlyLogins: false) { (success, error) -> Void in
			if success == false {
				print("Failed to fill into webview: <\(String(describing: error))>")
			}
		}
	}

	@IBAction func goBack(_ sender: AnyObject) {
		let navigation = webView.goBack()

		if navigation == nil {
			let htmlFilePath = Bundle.main.path(forResource: "welcome", ofType: "html")
			var htmlString : String!
			do {
				htmlString = try String(contentsOfFile: htmlFilePath!, encoding: String.Encoding.utf8)
			}
			catch {
				print("Failed to obtain the html string from file \(String(describing: htmlFilePath)) with error: <\(String(describing: error))>")
			}

			webView.loadHTMLString(htmlString, baseURL: URL(string: "https://agilebits.com"))
		}
	}
	@IBAction func goForward(_ sender: AnyObject) {
		webView.goForward()
	}

	// UISearchBarDelegate
	func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
		performSearch(text: searchBar.text ?? "")
	}

	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
		performSearch(text: searchBar.text ?? "")
	}

	func handleSearch(searchBar: UISearchBar) {
		performSearch(text: searchBar.text ?? "")
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		performSearch(text: searchBar.text ?? "")
	}

	// Convenience
	func performSearch(text: String) {
		let lowercaseText = text.lowercased(with: .current)
		var url: URL?

		let hasSpaces = lowercaseText.range(of: " ") != nil
		let hasDots = lowercaseText.range(of: ".") != nil

		let search = hasSpaces || hasDots
		if search {
			let hasScheme = lowercaseText.hasPrefix("http:") || lowercaseText.hasPrefix("https:")
			if hasScheme {
				url = URL(string: lowercaseText)
			}
			else {
				url = URL(string: "https://" + lowercaseText)
			}
		}

		if url == nil {
			let urlComponents = NSURLComponents()
			urlComponents.scheme = "https"
			urlComponents.host = "www.google.com"
			urlComponents.path = "/search"
			
			let queryItem = URLQueryItem(name: "q", value: text)
			urlComponents.queryItems = [queryItem]
			
			url = urlComponents.url
		}

		searchBar.text = url?.absoluteString
		searchBar.resignFirstResponder()

		if let url = url {
			webView.load(URLRequest(url: url))
		}
	}
	
	// WKNavigationDelegate
	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
		searchBar.text = webView.url?.absoluteString

		if searchBar.text == "about:blank" {
			searchBar.text = ""
		}
	}
}

