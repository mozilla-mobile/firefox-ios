// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct SchemesDefinition {
    enum standardSchemes: String {
        case http, https, javascript, data, about, sms, tel, facetime, mailto, blob, file
        case facetimeAudio = "facetime-audio"
        case appStore = "itms-apps"
        case appStores = "itms-appss"
        case internalURL = "internal"
    }

    static let appStoreSchemes = [
        standardSchemes.appStore,
        standardSchemes.appStores,
    ]

    /// List of schemes that are allowed to be opened in new tabs.
    static let allowedToBeOpenedAsPopups = [
        standardSchemes.http,
        standardSchemes.https,
        standardSchemes.javascript,
        standardSchemes.data,
        standardSchemes.about
    ]

    static let webpageSchemes = [
        standardSchemes.http, standardSchemes.https
    ]

    static let callingSchemes = [
        standardSchemes.sms, standardSchemes.tel, standardSchemes.facetime, standardSchemes.facetimeAudio
    ]

    /// The list of permanent URI schemes has been taken from http://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
    /// This list only contains accepted permanent schemes: historical and provisional schemes are not accepted.
    static let permanentURISchemes = [
        "aaa",
        "aaas",
        "about",
        "acap",
        "acct",
        "cap",
        "cid",
        "coap",
        "coaps",
        "crid",
        "data",
        "dav",
        "dict",
        "dns",
        "dtn",
        "example",
        "file",
        "ftp",
        "geo",
        "go",
        "gopher",
        "h323",
        "http",
        "https",
        "iax",
        "icap",
        "im",
        "imap",
        "info",
        "ipn",
        "ipp",
        "ipps",
        "iris",
        "iris.beep",
        "iris.lwz",
        "iris.xpc",
        "iris.xpcs",
        "jabber",
        "ldap",
        "leaptofrogans",
        "mailto",
        "mid",
        "msrp",
        "msrps",
        "mtqp",
        "mupdate",
        "news",
        "nfs",
        "ni",
        "nih",
        "nntp",
        "opaquelocktoken",
        "pkcs11",
        "pop",
        "pres",
        "reload",
        "rtsp",
        "rtsps",
        "rtspu",
        "service",
        "session",
        "shttp",
        "sieve",
        "sip",
        "sips",
        "sms",
        "snmp",
        "soap.beep",
        "soap.beeps",
        "stun",
        "stuns",
        "tag",
        "tel",
        "telnet",
        "tftp",
        "thismessage",
        "tip",
        "tn3270",
        "turn",
        "turns",
        "tv",
        "urn",
        "vemmi",
        "vnc",
        "ws",
        "wss",
        "xcon",
        "xcon-userid",
        "xmlrpc.beep",
        "xmlrpc.beeps",
        "xmpp",
        "z39.50r",
        "z39.50s"
    ]
}
