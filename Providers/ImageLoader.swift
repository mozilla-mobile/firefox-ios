/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

// A memory cache of recently found images
private let imgCache = LRUCache<String, UIImage>(cacheSize: 20)

// A list of in progress images that are loading, and the urls
// they are associated with. This allows us to coalesce if multiple queries
// are made for the same url at once.
private var imageLoadTasks = [String: ImageLoadTask]();

// A list of views and the tasks associated with the currently
// This is used to cancel the tasks associated with a view if the
// view is changed/recycled
private var loaders = [UIView: ImageLoader]()

// This queue holds all of the image/url loading tasks currently in progress
private let queue = NSOperationQueue()

// URL tasks handle fetching a url in a background thread queue.
class UrlLoadTask : NSOperation {
    private let task: () -> NSURL
    var url : NSURL? = nil
    
    init(callback: () -> NSURL) {
        task = callback
    }
    
    override func main() {
        url = task()
    }
}

// Handle loading images in a background queue
class ImageLoadTask : NSOperation {
    // The url to laod this image from
    private let url: NSURL

    // Holds the image after its loaded
    var img : UIImage? = nil

    // A set of blocks to call after this task is finished
    var callbacks = [ImageLoader]()

    init(url: NSURL) {
        self.url = url;
    }

    // NSOperation.main - Runs on the background thread when this task starts
    override func main() {
        img = ImageLoadTask.getForUrl(url);
    }

    // Add an image to the cache
    private class func addToCache(url: NSURL, img: UIImage?) {
        if let i = img {
            imgCache[url.absoluteString!] = i;
        }
    }

    // Get an image from a url
    class func getForUrl(url: NSURL) -> UIImage? {
        // Fast exit if its in the cache
        if let img = imgCache[url.absoluteString!] {
            return img
        }

        // Otherwise, load the image
        if (url.scheme == "resource") {
            let img = UIImage(named: url.host!);
            addToCache(url, img: img);
            return img;
        } else {
            if let data  = NSData(contentsOfURL: url) {
                let img = UIImage(data: data)
                addToCache(url, img: img);
                return img;
            }
        }

        return nil;
    }
}

class ImageLoader {
    // The view we will load this image into
    private var view: UIImageView?

    // An optional placeholder to show while we're loading the image
    private var placeholder: UIImage? = nil

    // The url to load the image from
    private var url: NSURL?

    // A list of callbacks to call after the image has been placed into the view
    private var thens : [(UIImage?) -> UIImage?] = [];

    // A list of callbacks to call before the image has been placed into the view
    private var postProcess : [(UIImage?) -> UIImage?] = [];

    // Tasks for fetching the url and the image
    private var urltask: UrlLoadTask
    private var imagetask: ImageLoadTask?

    // Crete an image loader. This will set things up, but will not start off url/image fetching until you specify a
    // view to load the image into
    init(siteUrlCallback: () -> NSURL) {
        self.urltask = UrlLoadTask(siteUrlCallback);
        urltask.completionBlock = {
            if (self.urltask.cancelled) {
                return;
            }

            if let url = self.urltask.url {
                self.getImage(url);
            }
        }

        self.url = urltask.url;
    }

    // Private method for getting an image
    private func getImage(url: NSURL) {
        // If we're already fetching the url, just append ourselves to the task's list of callbacks
        if let task = imageLoadTasks[url.absoluteString!] {
            task.callbacks.append(self);
            return;
        }

        // Create the task that will get the image
        self.imagetask = ImageLoadTask(url: url)
        imagetask!.completionBlock = {
            if (self.imagetask!.cancelled) {
                return
            }

            imageLoadTasks.removeValueForKey(url.absoluteString!)
            self.finishWithImage(self.imagetask!.img)
        }

        imagetask!.callbacks.append(self)
        imageLoadTasks[url.absoluteString!] = imagetask

        // Start loading the image
        queue.addOperation(imagetask!)
    }

    private func finishWithImage(img: UIImage?) {
        // Let any post processing happen
        var result = img
        for then in self.postProcess {
            result = then(result);
        }

        // When the task is done, call its callbacks on the main thread
        dispatch_async(dispatch_get_main_queue()) {
            if var task = self.imagetask {
                for callback in task.callbacks {
                    callback.finish(result);
                }
            } else {
                // If there is no image task, we probably had this result cached and tried to fast track out
                // Just finish for this view.
                self.finish(result)
            }
        }
    }

    // Called when the image loading is done
    func finish(result: UIImage?) {
        if let v = view {
            if let img = result {
                v.image = img
            }
        }

        // Now let the requestor do nay follow up work it wanted to do
        var img = result
        for then in thens {
            img = then(img);
        }
    }

    // Request that a placeholder image be shown while we're loading
    func placeholder(url: NSURL) -> ImageLoader {
        self.placeholder = ImageLoadTask.getForUrl(url)
        return self
    }
    
    // Request that a placeholder image be shown while we're loading
    func placeholder(image: UIImage) -> ImageLoader {
        self.placeholder = image
        return self;
    }

    // Cancels any in progress work. Note this may not cancel the load immediately, but should
    // cause any results found to be ignored.
    private func cancel() {
        urltask.cancel()

        if var i = imagetask {
            i.cancel()
            println("Cancel \(i.cancelled)")
        }

        if var v = view {
            loaders.removeValueForKey(v)
        }
    }

    // Specify a view to load this image into. If a second loader is created that also uses this
    // view, the first view will be cancelled
    func into(view: UIImageView) -> ImageLoader {
        // If our image is cached, we can do this super quick
        if var u = url {
            if var img = imgCache[u.absoluteString!] {
                finishWithImage(img)
                return self
            }
        }

        // If we were already loading something into this view, cancel it
        if var loader = loaders[view] {
            loader.cancel()
        }
        loaders[view] = self

        // Now start the url loading task
        self.view = view
        queue.addOperation(urltask)

        // Finally, show a placeholder while we're loading stuff
        if var p = placeholder {
            finishWithImage(p)
        }

        return self
    }

    // Adds a callback to be called at certain points in the process. If this is called before
    // 'into', the callback will be called on a background thread before the view is loaded into the image. Otherwise
    // it will be called after the image has been set.
    func then(callback: (UIImage?) -> UIImage?) -> ImageLoader {
        if view == nil {
            postProcess.append(callback)
        } else {
            thens.append(callback)
        }
        return self
    }
}
