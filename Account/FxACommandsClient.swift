/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
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
            let client = FxAClient10(configuration: self.account.configuration)
            return client.invokeCommand(name: commandName, targetDeviceID: deviceID, payload: payload, withSessionToken: sessionToken)
        }
    }

    public func consumeRemoteCommand(index: Int) -> Deferred<Maybe<[FxACommandSendTabItem]>> {
        return fetchRemoteCommands(index: index, limit: 1) >>== { response in
            let commands = response.commands
            if commands.count != 1 {
                log.warning("[FxA Commands] Should have retrieved 1 and only 1 message, got \(commands.count)")
            }

            let prefs = self.account.configuration.prefs
            var handledCommands = prefs.arrayForKey(PrefsKeys.KeyFxAHandledCommands) as? [Int] ?? []
            handledCommands.append(contentsOf: commands.map({ $0.index }))

            prefs.setObject(handledCommands, forKey: PrefsKeys.KeyFxAHandledCommands)

            return self.handleCommands(commands) >>== { items in
                // Once the `handledCommands` array length passes a threshold, check the
                // potentially missed remote commands in order to clear it.
                if handledCommands.count > 20 {
                    return self.fetchMissedRemoteCommands() >>== { missedItems in
                        return deferMaybe(items + missedItems)
                    }
                } else {
                    return deferMaybe(items)
                }
            }
        }
    }

    public func fetchMissedRemoteCommands() -> Deferred<Maybe<[FxACommandSendTabItem]>> {
        let prefs = account.configuration.prefs
        let lastCommandIndex = Int(prefs.intForKey(PrefsKeys.KeyFxALastCommandIndex) ?? 0)
        var handledCommands = prefs.arrayForKey(PrefsKeys.KeyFxAHandledCommands) as? [Int] ?? []

        handledCommands.append(lastCommandIndex)

        return fetchRemoteCommands(index: lastCommandIndex) >>== { response in
            let missedCommands = response.commands.filter({ !handledCommands.contains($0.index) })
            prefs.setInt(Int32(lastCommandIndex), forKey: PrefsKeys.KeyFxALastCommandIndex)
            prefs.setObject([], forKey: PrefsKeys.KeyFxAHandledCommands)

            return self.handleCommands(missedCommands)
        }
    }

    func fetchRemoteCommands(index: Int, limit: UInt? = nil) -> Deferred<Maybe<FxACommandsResponse>> {
        return account.marriedState() >>== { marriedState in
            let sessionToken = marriedState.sessionToken as NSData
            let client = FxAClient10(configuration: self.account.configuration)
            return client.commands(atIndex: index, limit: limit, withSessionToken: sessionToken)
        }
    }

    func handleCommands(_ commands: [FxACommand]) -> Deferred<Maybe<[FxACommandSendTabItem]>> {
        return account.marriedState() >>== { marriedState in
            let sessionToken = marriedState.sessionToken as NSData
            let client = FxAClient10(configuration: self.account.configuration)
            return client.devices(withSessionToken: sessionToken) >>== { response in
                let devices = response.devices

                func handleCommand(_ command: FxACommand) -> FxACommandSendTabItem? {
                    guard let commandName = command.data["command"].string,
                        let encrypted = command.data["payload"]["encrypted"].string,
                        let senderDeviceID = command.data["sender"].string,
                        let sender = devices.find({ $0.id == senderDeviceID }) else {
                        log.error("[FxA Commands] Invalid payload received for command \(command.index)")
                        return nil
                    }

                    switch commandName {
                    case FxACommandSendTab.Name:
                        return self.sendTab.handle(sender: sender, encrypted: encrypted)
                    default:
                        log.info("[FxA Commands] Unknown command: \(commandName)")
                        return nil
                    }
                }

                let items = commands.compactMap({ handleCommand($0) })
                return deferMaybe(items)
            }
        }
    }
}

public struct FxACommandSendTabItem {
    public let title: String
    public let url: String
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

public struct FxACommandSendTabReport {
    fileprivate(set) public var succeeded: [RemoteDevice]
    fileprivate(set) public var failed: [RemoteDevice]
}

open class FxACommandSendTab {
    public static let Name = "https://identity.mozilla.com/cmd/open-uri"

    let commandsClient: FxACommandsClient
    let account: FirefoxAccount
    let sendTabKeysCache: KeychainCache<FxACommandSendTabKeys>

    init(commandsClient: FxACommandsClient, account: FirefoxAccount) {
        self.commandsClient = commandsClient
        self.account = account
        self.sendTabKeysCache = KeychainCache.fromBranch("account.sendTabKeys", withLabel: account.stateCache.label, factory: { json in
            if let publicKey = json["publicKey"].string,
                let privateKey = json["privateKey"].string,
                let authSecret = json["authSecret"].string {
                return FxACommandSendTabKeys(publicKey: publicKey, privateKey: privateKey, authSecret: authSecret)
            }

            log.error("[FxA Commands] No sendTabKeys found in Keychain")
            return nil
        })
    }

    public func send(to devices: [RemoteDevice], url: String, title: String) -> Deferred<Maybe<FxACommandSendTabReport>> {
        let json = JSON([
            "entries": [["title": title, "url": url]]
        ])

        guard let jsonString = json.stringify() else {
            return deferMaybe(FxACommandsClientError())
        }

        let deferreds = devices.map { device in
            return encrypt(message: jsonString, device: device) >>== { encryptedPayload in
                self.commandsClient.invoke(commandName: FxACommandSendTab.Name, toDevice: device, withPayload: encryptedPayload).bind { result in
                    return deferMaybe((device: device, success: result.isSuccess))
                }
            }
        }

        return all(deferreds).bind { results in
            let tuples = results.compactMap({ $0.successValue })
            let succeeded = tuples.filter({ $0.success }).map({ $0.device })
            let failed = tuples.filter({ !$0.success }).map({ $0.device })

            if failed.count > 0 {
                log.warning("[FxA Commands] Failed to send tab to \(failed.count) device(s); Falling back to old Sync backend")
            }

            return deferMaybe(FxACommandSendTabReport(succeeded: succeeded, failed: failed))
        }
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

    public func handle(sender: FxADevice, encrypted: String) -> FxACommandSendTabItem? {
        guard let decrypted = decrypt(ciphertext: encrypted) else {
            log.error("[FxA Commands] Unable to decrypt command received from device '\(sender.name)' (\(sender.id ?? "nil"))")
            return nil
        }

        let json = JSON(parseJSON: decrypted)

        guard let entries = json["entries"].array else {
            log.error("[FxA Commands] No 'entries' array in JSON received from device '\(sender.name)' (\(sender.id ?? "nil"))")
            return nil
        }

        let current = json["current"].int ?? entries.count - 1

        guard let tab = entries[safe: current],
            let title = tab["title"].string,
            let url = tab["url"].string else {
            log.error("[FxA Commands] No tab for entry \(current) in JSON received from device '\(sender.name)' (\(sender.id ?? "nil"))")
            return nil
        }

        return FxACommandSendTabItem(title: title, url: url)
    }

    func encrypt(message: String, device: RemoteDevice) -> Deferred<Maybe<String>> {
        return account.marriedState() >>== { marriedState in
            guard let bundleString = device.availableCommands?[FxACommandSendTab.Name].string else {
                return deferMaybe(FxACommandsClientError())
            }

            let bundle = JSON(parseJSON: bundleString)
            let syncKeyBundle = KeyBundle.fromKSync(marriedState.kSync)

            // Decrypt the key bundle for the target `device` using `kSync`.
            guard let cipherdataString = bundle["ciphertext"].string,
                let ivString = bundle["IV"].string,
                let cipherdata = Bytes.decodeBase64(cipherdataString),
                let iv = Bytes.decodeBase64(ivString),
                let decryptedKeyString = syncKeyBundle.decrypt(cipherdata, iv: iv) else {
                return deferMaybe(FxACommandsClientError())
            }

            let decryptedKey = JSON(parseJSON: decryptedKeyString)
            let plaintext = message.utf8EncodedData

            // Using the decrypted key bundle for the target `device`, encrypt
            // the message using aes128gcm.
            guard let publicKey = decryptedKey["publicKey"].string?.base64urlSafeDecodedData,
                let authSecret = decryptedKey["authSecret"].string?.base64urlSafeDecodedData,
                let result = (try? PushCrypto.sharedInstance.aes128gcm(plaintext: plaintext, encryptWith: publicKey, authenticateWith: authSecret).base64urlSafeEncodedString) else {
                return deferMaybe(FxACommandsClientError())
            }

            return deferMaybe(result)
        }
    }

    func decrypt(ciphertext: String) -> String? {
        guard let sendTabKeys = self.sendTabKeysCache.value,
            let decrypted = try? PushCrypto.sharedInstance.aes128gcm(payload: ciphertext, decryptWith: sendTabKeys.privateKey, authenticateWith: sendTabKeys.authSecret) else {
                return nil
        }

        return decrypted
    }

    func generateAndPersistKeys() -> FxACommandSendTabKeys? {
        guard let keys = try? PushCrypto.sharedInstance.generateKeys() else {
            return nil
        }

        let sendTabKeys = FxACommandSendTabKeys(publicKey: keys.p256dhPublicKey, privateKey: keys.p256dhPrivateKey, authSecret: keys.auth)

        // Save to Keychain.
        sendTabKeysCache.value = sendTabKeys

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

        guard let cleartext = keyToEncrypt.stringify(),
            let (ciphertext, iv) = keyBundle.encrypt(cleartext.utf8EncodedData) else {
            return nil
        }

        let hmacString = keyBundle.hmacString(ciphertext.base64EncodedData())
        let ivString = iv.base64EncodedString
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
