/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Deferred
import Shared
import SwiftyJSON

private let log = Logger.syncLogger

public struct FxACommand {
    let index: Int
    let data: JSON

    static func fromJSON(_ json: JSON) -> FxACommand? {
        guard json.error == nil,
            let index = json["index"].int else {
                return nil
        }

        let data = json["data"]

        return FxACommand(index: index, data: data)
    }
}

public class FxACommandsClientError: MaybeErrorType {
    public var description = "An error occurred within the FxACommandsClient."
}

public class FxACommandsClient {
    private(set) open var sendTab: FxACommandSendTab!

    let account: FirefoxAccount

    init(account: FirefoxAccount) {
        self.account = account

        self.sendTab = FxACommandSendTab(commandsClient: self, account: account)
    }

    public func invoke(commandName: String, toDevice device: RemoteDevice, withPayload payload: String) -> Deferred<Maybe<FxASendMessageResponse>> {
        guard let deviceID = device.id else {
            return deferMaybe(FxACommandsClientError())
        }

        return account.marriedState() >>== { marriedState in
            let sessionToken = marriedState.sessionToken as NSData
            let client = FxAClient10(authEndpoint: self.account.configuration.authEndpointURL)
            return client.invokeCommand(name: commandName, targetDeviceID: deviceID, payload: payload, withSessionToken: sessionToken)
        }
    }

    public func consumeRemoteCommand(index: Int) {
        fetchRemoteCommands(index: index, limit: 1) >>== { response in
            let commands = response.commands
            if commands.count != 1 {
                log.warning("Should have retrieved 1 and only 1 message, got \(commands.count)")
            }

            let prefs = self.account.configuration.prefs
            var handledCommands = prefs?.arrayForKey(PrefsKeys.KeyFxAHandledCommands) as? [Int] ?? []
            handledCommands.append(contentsOf: commands.map({ $0.index }))

            prefs?.setObject(handledCommands, forKey: PrefsKeys.KeyFxAHandledCommands)

            self.handleCommands(commands)

            // Once the `handledCommands` array length passes a threshold, check the
            // potentially missed remote commands in order to clear it.
            if handledCommands.count > 20 {
                self.fetchMissedRemoteCommands()
            }
        }
    }

    public func fetchMissedRemoteCommands() {
        let prefs = account.configuration.prefs
        let lastCommandIndex = Int(prefs?.intForKey(PrefsKeys.KeyFxALastCommandIndex) ?? 0)
        var handledCommands = prefs?.arrayForKey(PrefsKeys.KeyFxAHandledCommands) as? [Int] ?? []

        handledCommands.append(lastCommandIndex)

        fetchRemoteCommands(index: lastCommandIndex) >>== { response in
            let missedCommands = response.commands.filter({ !handledCommands.contains($0.index) })
            prefs?.setInt(Int32(lastCommandIndex), forKey: PrefsKeys.KeyFxALastCommandIndex)
            prefs?.setObject([], forKey: PrefsKeys.KeyFxAHandledCommands)

            if !missedCommands.isEmpty {
                self.handleCommands(missedCommands)
            }
        }
    }

    func fetchRemoteCommands(index: Int, limit: UInt? = nil) -> Deferred<Maybe<FxACommandsResponse>> {
        return account.marriedState() >>== { marriedState in
            let sessionToken = marriedState.sessionToken as NSData
            let client = FxAClient10(authEndpoint: self.account.configuration.authEndpointURL)
            return client.commands(atIndex: index, limit: limit, withSessionToken: sessionToken)
        }
    }

    func handleCommands(_ commands: [FxACommand]) {
        return account.marriedState() >>== { marriedState in
            let sessionToken = marriedState.sessionToken as NSData
            let client = FxAClient10(authEndpoint: self.account.configuration.authEndpointURL)
            client.devices(withSessionToken: sessionToken) >>== { response in
                let devices = response.devices

                for command in commands {
                    guard let commandName = command.data["command"].string,
                        let payload = command.data["payload"].string,
                        let senderDeviceID = command.data["sender"].string,
                        let sender = devices.find({ $0.id == senderDeviceID }) else {
                            continue
                    }

                    switch commandName {
                    case FxACommandSendTab.Name:
                        self.sendTab.handle(sender: sender, encrypted: payload)
                    default:
                        log.info("Unknown command: \(commandName)")
                    }
                }
            }
        }
    }
}

open class FxACommandSendTabKeys: JSONLiteralConvertible {
    open var publicKey: String
    open var privateKey: String
    open var authSecret: String

    public init(publicKey: String, privateKey: String, authSecret: String) {
        self.publicKey = publicKey
        self.privateKey = privateKey
        self.authSecret = authSecret
    }

    open func asJSON() -> JSON {
        return JSON([
            "publicKey": self.publicKey,
            "privateKey": self.privateKey,
            "authSecret": self.authSecret
        ])
    }
}

open class FxACommandSendTab {
    public static let Name = "https://identity.mozilla.com/cmd/open-uri"

    let commandsClient: FxACommandsClient
    let account: FirefoxAccount
    let sendTabKeysCache: KeychainCache<FxACommandSendTabKeys>

    init(commandsClient: FxACommandsClient, account: FirefoxAccount) {
        self.commandsClient = commandsClient
        self.account = account
        self.sendTabKeysCache = KeychainCache(branch: "account.sendTabKeys", label: account.stateCache.label, value: nil)
    }

    public func send(to devices: [RemoteDevice], url: String, title: String) {
        let json = JSON([
            "entries": [["title": title, "url": url]]
        ])

        guard let jsonString = json.stringValue() else {
            return
        }

        for device in devices {
            encrypt(message: jsonString, device: device) >>== { encryptedPayload in
                self.commandsClient.invoke(commandName: FxACommandSendTab.Name, toDevice: device, withPayload: encryptedPayload).bind { result in
                    return deferMaybe(result.isSuccess)
                }
            }
        }

        // TODO: gather stats here about success/failures
    }

    public func isDeviceCompatible(_ device: RemoteDevice) -> Bool {
        guard let marriedState = account.stateCache.value as? MarriedState,
            let availableCommands = device.availableCommands else {
            return false
        }

        guard let sendTabCommandString = availableCommands[FxACommandSendTab.Name].string else {
            return false
        }

        let sendTabCommand = JSON(parseJSON: sendTabCommandString)

        guard let theirKid = sendTabCommand["kid"].string else {
            return false
        }

        return theirKid == marriedState.kXCS
    }

    public func handle(sender: FxADevice, encrypted: String) {
        guard let decrypted = decrypt(ciphertext: encrypted) else {
            return
        }

        let json = JSON(parseJSON: decrypted)

        guard let entries = json["entries"].array else {
            return
        }

        let current = json["current"].int ?? entries.count - 1

        guard let tab = entries[safe: current],
            let title = tab["title"].string,
            let url = tab["uri"].string else {
            return
        }

        print("Received tab: \(title)(\(url))")
        // TODO: Maybe use NotificationCenter to alert the app that this tab was received?
    }

    // TODO: Check this
    func encrypt(message: String, device: RemoteDevice) -> Deferred<Maybe<String>> {
        return account.marriedState() >>== { marriedState in
            guard let bundleString = device.availableCommands?[FxACommandSendTab.Name].string else {
                return deferMaybe(FxACommandsClientError())
            }

            let bundle = JSON(parseJSON: bundleString)
            let syncKeyBundle = KeyBundle.fromKSync(marriedState.kSync)

            guard let cipherdataString = bundle["ciphertext"].string,
                let ivString = bundle["IV"].string,
                let cipherdata = Bytes.decodeBase64(cipherdataString),
                let iv = Bytes.decodeBase64(ivString),
                let decryptedKeyString = syncKeyBundle.decrypt(cipherdata, iv: iv) else {
                return deferMaybe(FxACommandsClientError())
            }

            let decryptedKey = JSON(parseJSON: decryptedKeyString)

            guard let publicKey = decryptedKey["publicKey"].string?.base64urlSafeDecodedData,
                let authSecret = decryptedKey["authSecret"].string?.base64urlSafeDecodedData,
                let plaintext = message.data(using: .utf8),
                let result = (try? PushCrypto.sharedInstance.aes128gcm(plaintext: plaintext, encryptWith: publicKey, authenticateWith: authSecret, rs: plaintext.count, padLen: 0).base64urlSafeEncodedString) as? String else {
                return deferMaybe(FxACommandsClientError())
            }

            return deferMaybe(result)
        }
    }

    // TODO: Check this
    func decrypt(ciphertext: String) -> String? {
        guard let sendTabKeys = self.sendTabKeysCache.value,
            let publicKey = sendTabKeys.publicKey.base64urlSafeDecodedData,
            let authSecret = sendTabKeys.authSecret.base64urlSafeDecodedData,
            let cipherdata = ciphertext.base64urlSafeDecodedData,
            let decrypted = try? PushCrypto.sharedInstance.aes128gcm(payload: cipherdata, decryptWith: publicKey, authenticateWith: authSecret) else {
                return nil
        }

        return decrypted.utf8EncodedString
    }

    func generateAndPersistKeys() -> FxACommandSendTabKeys? {
        guard let keys = try? PushCrypto.sharedInstance.generateKeys() else {
            return nil
        }

        let sendTabKeys = FxACommandSendTabKeys(publicKey: keys.p256dhPublicKey, privateKey: keys.p256dhPrivateKey, authSecret: keys.auth)

        // Save to Keychain.
        sendTabKeysCache.value = sendTabKeys

        if let prefsBranchPrefix = account.configuration.prefs?.getBranchPrefix() {
            print(prefsBranchPrefix)
        }

        return sendTabKeys
    }

    func getEncryptedKey() -> String? {
        guard let sendTabKeys = self.sendTabKeysCache.value ?? generateAndPersistKeys(),
            let marriedState = account.stateCache.value as? MarriedState else {
            return nil
        }

        let keyToEncrypt = JSON([
            "publicKey": sendTabKeys.publicKey,
            "authSecret": sendTabKeys.authSecret
        ])

        let keyBundle = KeyBundle.fromKSync(marriedState.kSync)

        guard let cleartext = try? keyToEncrypt.rawData(options: []),
            let (ciphertext, iv) = keyBundle.encrypt(cleartext) else {
            return nil
        }

        let hmac = keyBundle.hmac(ciphertext)
        let ivString = iv.base64EncodedString
        let hmacString = hmac.hexEncodedString
        let ciphertextString = ciphertext.base64EncodedString

        let encryptedKey = JSON([
            "kid": marriedState.kXCS,
            "IV": ivString,
            "hmac": hmacString,
            "ciphertext": ciphertextString
        ])

        return encryptedKey.rawString(options: [])?.replacingOccurrences(of: "\\/", with: "/")
    }
}
