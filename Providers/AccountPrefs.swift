// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class AccountPrefs : NSUserDefaults {
    private let account:Account

    init?(account: Account) {
        self.account = account
        super.init(suiteName: SuiteName)
    }

    private func qualifyKey(key:String) -> String {
        return self.account.user + key
    }
    
    override func setBool(value: Bool, forKey defaultName: String) {
        super.setBool(value, forKey: qualifyKey(defaultName))
    }

    override func setDouble(value: Double, forKey defaultName: String) {
        super.setDouble(value, forKey: qualifyKey(defaultName))
    }

    override func setInteger(value: Int, forKey defaultName: String) {
        super.setInteger(value, forKey: qualifyKey(defaultName))
    }

    override func setFloat(value: Float, forKey defaultName: String) {
        super.setFloat(value, forKey: qualifyKey(defaultName))
    }

    override func setNilValueForKey(key: String) {
        super.setNilValueForKey(qualifyKey(key))
    }

    override func setObject(value: AnyObject?, forKey defaultName: String) {
        super.setObject(value, forKey: qualifyKey(defaultName))
    }

    override func setPersistentDomain(domain: [NSObject : AnyObject], forName domainName: String) {
        super.setPersistentDomain(domain, forName: qualifyKey(domainName))
    }

    override func setURL(url: NSURL, forKey defaultName: String) {
        super.setURL(url, forKey: qualifyKey(defaultName))
    }

    override func setValue(value: AnyObject?, forKey key: String) {
        super.setValue(value, forKey: qualifyKey(key))
    }

    override func setValue(value: AnyObject?, forKeyPath keyPath: String) {
        super.setValue(value, forKeyPath: qualifyKey(keyPath))
    }

    override func setValue(value: AnyObject?, forUndefinedKey key: String) {
        super.setValue(value, forUndefinedKey: qualifyKey(key))
    }

    override func boolForKey(defaultName: String) -> Bool {
        return super.boolForKey(qualifyKey(defaultName))
    }

    override func stringForKey(defaultName: String) -> String? {
        return super.stringForKey(qualifyKey(defaultName))
    }

    override func integerForKey(defaultName: String) -> Int {
        return super.integerForKey(qualifyKey(defaultName))
    }

    override func doubleForKey(defaultName: String) -> Double {
        return super.doubleForKey(qualifyKey(defaultName))
    }

    override func floatForKey(defaultName: String) -> Float {
        return super.floatForKey(qualifyKey(defaultName))
    }

    override func stringArrayForKey(defaultName: String) -> [AnyObject]? {
        return super.stringArrayForKey(qualifyKey(defaultName))
    }

    override func arrayForKey(defaultName: String) -> [AnyObject]? {
        return super.arrayForKey(qualifyKey(defaultName))
    }

    override func dictionaryForKey(defaultName: String) -> [NSObject : AnyObject]? {
        return super.dictionaryForKey(qualifyKey(defaultName))
    }

    override func URLForKey(defaultName: String) -> NSURL? {
        return super.URLForKey(qualifyKey(defaultName))
    }
    
    override func removeObjectForKey(defaultName: String) {
        super.removeObjectForKey(qualifyKey(defaultName));
    }
}
