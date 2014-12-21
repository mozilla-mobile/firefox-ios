/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ReaderViewController: UIViewController, UIWebViewDelegate {

    @IBOutlet weak var webView: UIWebView!
    
    var urlSpec: String!

    private var docLoaded = false

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Loading reader content..."

        let url = NSURL(string: urlSpec)!
        let request = NSURLRequest(URL: url)
        webView.delegate = self
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func close(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        if (docLoaded) {
            // We've already handled the load event for this document.
            return
        }

        let readyJS = "document.readyState == 'complete'"
        let result = webView.stringByEvaluatingJavaScriptFromString(readyJS)
        if (result == "false") {
            // The load event was for a subframe. Ignore.
            return
        }

        docLoaded = true

        let readabilityJS = getReadabilityJS()
        webView.stringByEvaluatingJavaScriptFromString(readabilityJS)
        webView.stringByEvaluatingJavaScriptFromString("var reader = new Readability('', document); var readerResult = reader.parse();")

        // TODO: Cache the article.
        let title = webView.stringByEvaluatingJavaScriptFromString("readerResult.title")
        let content = webView.stringByEvaluatingJavaScriptFromString("readerResult.content")

        // Set the reader title and content in the WebView.
        self.title = title
        let aboutUrl = NSURL(string: "about:reader")
        webView.loadHTMLString(content, baseURL: aboutUrl)
    }

    func getReadabilityJS() -> String {
        let fileRoot = NSBundle.mainBundle().pathForResource("Readability", ofType: "js")
        return NSString(contentsOfFile: fileRoot!, encoding: NSUTF8StringEncoding, error: nil)!
    }
}
