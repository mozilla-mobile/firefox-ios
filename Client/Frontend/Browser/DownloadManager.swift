/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

@objc
class Download : NSObject {
    // Stream to write to disk
    var outputStream: NSOutputStream? = nil
    // In memory cache if the disk stream is slow
    var data: NSMutableData?

    var response: NSURLResponse?
    let completionHandler: ((download: Download) -> Void)?

    // Snackbar showing progress of this download
    var snackBar: SnackBar? = nil

    // The browser that started this download
    weak var tab: Browser?
    let url: NSURL
    private var closeWhenDone = false

    // Background task ID. We'll use this to try and keep the download alive even if the user exits.
    private var taskId: UIBackgroundTaskIdentifier? = nil

    // Helper for prompting to start a download
    class func promptForDownload(url: NSURL, tab: Browser) {
        let title = NSLocalizedString("Download the file at %@?", comment: "Prompt for downloading a file. File url will be shown.")
        let filledTitle = String(format: title, url)
        let bar = SnackBar(text: filledTitle, img: nil, buttons: [
            SnackButton(title: NSLocalizedString("Cancel", comment: "Download prompt cancel download button"), callback: { bar in
                tab.removeSnackbar(bar)
                return
            }),
            SnackButton(title: NSLocalizedString("Download", comment: "Download prompt start download button"), callback: { bar in
                tab.removeSnackbar(bar)
                var download = Download(url: url, forTab: tab) { download in
                    download.promptOpen()
                }
            }),
            ])
        tab.addSnackbar(bar)
    }

    // Helper for getting the download size. For unknown sizes, we just return something huge.
    var expectedContentLength: Int64 {
        return response?.expectedContentLength ?? INT64_MAX
    }

    // Helper for initializing a download
    func promptOpen() {
        let title = NSLocalizedString("Downloaded %@", comment: "Download complete dialog title. Will show the downloaded filename.")
        let filledTitle = String(format: title, filename ?? url)
        let bar = SnackBar(text: filledTitle, img: nil, buttons: [
            SnackButton(title: NSLocalizedString("Close", comment: "Close button on the download complete prompt."), callback: { bar in
                self.tab?.removeSnackbar(bar)
                return
            }),
            SnackButton(title: NSLocalizedString("Open", comment: "Open button the download complete prompt."), callback: { bar in
                self.open()
                self.tab?.removeSnackbar(bar)
                return
            }),
            ])
        tab?.addSnackbar(bar)
    }

    private init(url: NSURL, forTab tab: Browser, completionHandler: ((download: Download) -> Void)? = nil) {
        self.completionHandler = completionHandler
        self.url = url
        self.tab = tab

        super.init()

        var request = NSURLRequest(URL: url, cachePolicy: NSURLRequestCachePolicy.ReloadIgnoringLocalCacheData, timeoutInterval: 20.0)
        var connection = NSURLConnection(request: request, delegate: self)!

        connection.start()
    }

    private var filename: String {
        // TODO: If this file already exists, we need to generate a unique name
        return response?.suggestedFilename ?? self.url.lastPathComponent!
    }

    private var file: String {
        let manager = NSFileManager.defaultManager()
        let docsDir = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0] as! String

        println("Filename \(docsDir.stringByAppendingPathComponent(filename))")
        return docsDir.stringByAppendingPathComponent(filename)
    }

    private var length: Int = 0

    /// Shows a popup to open the local file in other apps.
    func open(viewController: UIViewController? = nil) {
        var res: [AnyObject] = [NSURL(fileURLWithPath: file)!]

        var activityViewController = UIActivityViewController(activityItems: res, applicationActivities: nil)
        if let popoverPresentationController = activityViewController.popoverPresentationController {
            popoverPresentationController.sourceView = tab?.webView
            popoverPresentationController.sourceRect = tab!.webView.frame
            popoverPresentationController.permittedArrowDirections = .Any
        }

        tab?.webView.window?.rootViewController?.presentViewController(activityViewController, animated: true, completion: nil)
    }
}

extension Download : NSURLConnectionDataDelegate {
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        promptOpen()
    }

    func connection(connection: NSURLConnection, willCacheResponse cachedResponse: NSCachedURLResponse) -> NSCachedURLResponse? {
        return nil
    }

    /// Called when the download ends.
    func connectionDidFinishLoading(connection: NSURLConnection) {
        // If we've written everything, we can close up.
        if self.data?.length ?? 0 == 0 {
            closeStream()
        } else {
            // If there's still data to write, finish writing it.
            closeWhenDone = true
        }

        if let snackBar = self.snackBar {
            tab?.removeSnackbar(snackBar)
        }

        // Notify history about this download.
        let notificationCenter = NSNotificationCenter.defaultCenter()
        var info = [NSObject: AnyObject]()
        info["url"] = url
        info["type"] = VisitType.Download.rawValue
        notificationCenter.postNotificationName("LocationChange", object: self, userInfo: info)

        // Notify whoever started the download about it
        completionHandler?(download: self)
    }

    /// Called when the download starts.
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        // Create and show a progress snackbar while the download is downloading
        let title = NSLocalizedString("Downloading %@", comment: "Downloading dialog title. Will show the downloading filename.")
        let filledTitle = String(format: title, filename ?? url)

        snackBar = SnackBar(attrText: NSAttributedString(string: filledTitle), img: nil, buttons: [SnackButton(title: NSLocalizedString("Cancel", comment: "Cancel the in-progress download"), callback: { bar in
            connection.cancel()
            self.tab?.removeSnackbar(bar)
        })]
        )

        snackBar?.setProgress(0, animated: false)
        tab?.addSnackbar(snackBar!)

        self.response = response
        self.data = NSMutableData()
        self.outputStream = NSOutputStream(toFileAtPath: file, append: false)
        self.outputStream?.delegate = self
        self.outputStream?.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        self.outputStream?.open()
        self.taskId = UIApplication.sharedApplication().beginBackgroundTaskWithName("Download \(url)", expirationHandler: { () -> Void in
            self.taskId = nil
            self.closeStream()
            self.deleteFile()
        })
    }

    func deleteFile() {
        NSFileManager.defaultManager().removeItemAtPath(self.file, error: nil)
    }

    /// Called when the download's progress changes.
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        // If we don't have any data buffered, and the stream is available for writing, we have to try and
        // write to it here.
        if (self.data?.length ?? 0 == 0 && outputStream!.streamStatus == .Open && outputStream!.hasSpaceAvailable) {
            let wrote = outputStream?.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length) ?? 0
            self.data?.appendData(data.subdataWithRange(NSRange(location: wrote, length: data.length - wrote)))
        } else {
            // Otherwise we store it in a memory cache
            self.data?.appendData(data)
        }

        length += data.length
        let progress = Float(length) / Float(expectedContentLength)
        snackBar?.setProgress(progress, animated: true)
    }
}

extension Download : NSStreamDelegate {
    func stream(theStream: NSStream, handleEvent streamEvent: NSStreamEvent) {
        // TODO: Better handle error events in here.
        if streamEvent == NSStreamEvent.HasSpaceAvailable {
            // If we've got data around, try and store it
            if data?.length ?? 0 > 0 {
                let wrote = outputStream?.write(UnsafePointer<UInt8>(data!.bytes), maxLength: length) ?? 0
                data!.replaceBytesInRange(NSRange(location: 0, length: wrote), withBytes: nil, length: 0)
            }

            // If we're out of data, and the server is done sending us data, close the stream
            if data?.length ?? 0 == 0 && closeWhenDone  {
                closeStream()
            }
        }
    }

    private func closeStream() {
        outputStream?.close()
        outputStream?.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSDefaultRunLoopMode)
        outputStream = nil
        data = nil
        closeWhenDone = false
        if let taskId = taskId {
            UIApplication.sharedApplication().endBackgroundTask(taskId)
        }
    }
}
