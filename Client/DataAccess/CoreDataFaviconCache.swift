/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// XXX - I would like this to be CoreDataFaviconCache: GenericCache<String, [Favicon]>
//       i.e. not generic. Swift won't let me make it non-generic though, so I have to have templates
//       on CoreDataFaviconCache. It also fails if I make that generic but make GenericCache specific. i.e.
//       CoreDataFaviconCache<K,V> : GenericCache<String, [Favicon]>. The best fix I've found so far
//       is to leave everything generic and cast when I need to.

// Maintains a cache of site urls -> favicons using core data
class CoreDataFaviconCache<K,V> : GenericCache<K, V> {
    override subscript(key: KeyType) -> ValueType? {
        get {
            var res = [Favicon]()
            var site = Site.MR_findFirstOrCreateByAttribute("url", withValue: key as? String)
            for favicon in site.favicons {
                if var icon = favicon as? Favicon {
                    res.append(icon)
                }
            }

            if (res.count == 0) {
                return nil
            }

            return res as? ValueType
        }

        set(newValue) {
            MagicalRecord.saveWithBlockAndWait { context in
                var site = Site.MR_findFirstOrCreateByAttribute("url", withValue: key as? String, inContext: context)
                // Clear any previously set favicons for this site
                for favicon in site.favicons {
                    if var icon = favicon as? Favicon {
                        site.removeFavicon(icon)
                    }
                }

                // Now add the new ones
                if var favicons = newValue as? [Favicon] {
                    for favicon in favicons {
                        var icon = Favicon.MR_findFirstOrCreateByAttribute("url", withValue: favicon.url, inContext: context)
                        icon.updatedDate = favicon.updatedDate
                        icon.image = favicon.image

                        site.addFavicon(icon)
                    }
                }
            }
        }
    }

    internal override func clear() {
        MagicalRecord.saveWithBlockAndWait { context in
            var items = Site.MR_findAll()
            for item in items {
                item.MR_deleteEntityInContext(context)
            }

            items = Favicon.MR_findAll()
            for item in items {
                item.MR_deleteEntityInContext(context)
            }
        }
    }
}
