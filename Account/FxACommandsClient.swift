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

    public func send(commandName: String, toDevice device: FxADevice, withPayload payload: String) -> Deferred<Maybe<FxASendMessageResponse>> {
        guard let deviceID = device.id else {
            return deferMaybe(FxACommandsClientError())
        }

        return account.marriedState() >>== { marriedState in
            let sessionToken = marriedState.sessionToken as NSData
            let client = FxAClient10(authEndpoint: self.account.configuration.authEndpointURL)
            return client.invokeCommand(name: commandName, targetDeviceID: deviceID, payload: payload, withSessionToken: sessionToken)
        }
    }

    public func consumeRemoteCommand(index: UInt) {
        fetchRemoteCommands(index: index, limit: 1) >>== { response in
            let commands = response.commands
            if commands.count != 1 {
                log.warning("Should have retrieved 1 and only 1 message, got \(commands.count)")
            }

/*
             return this._fxAccounts._withCurrentAccountState(async (getUserData, updateUserData) => {
                 const {device} = await getUserData(["device"]);
                 if (!device) {
                     throw new Error("No device registration.");
                 }
                 const handledCommands = (device.handledCommands || []).concat(messages.map(m => m.index));
                 await updateUserData({
                     device: {...device, handledCommands}
                 });
                 await this._handleCommands(messages);

                 // Once the handledCommands array length passes a threshold, check the
                 // potentially missed remote commands in order to clear it.
                 if (handledCommands.length > 20) {
                     await this.fetchMissedRemoteCommands();
                 }
             });
*/
        }
    }

    public func fetchMissedRemoteCommands() {

    }

    func fetchRemoteCommands(index: UInt, limit: UInt? = nil) -> Deferred<Maybe<FxACommandsResponse>> {
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

    fileprivate var sendTabKeys: [String : String]?

    init(commandsClient: FxACommandsClient, account: FirefoxAccount) {
        self.commandsClient = commandsClient
        self.account = account
    }

    public func send(to devices: [FxADevice], url: String, title: String) {
        let json = JSON([
            "entries": [["title": title, "url": url]]
        ])

        guard let jsonString = json.stringValue() else {
            return
        }

        for device in devices {
            encrypt(message: jsonString, device: device) >>== { encryptedPayload in
                self.commandsClient.send(commandName: FxACommandSendTab.Name, toDevice: device, withPayload: encryptedPayload).bind { result in
                    return deferMaybe(result.isSuccess)
                }
            }
        }

        // TODO: gather stats here about success/failures
    }

    public func isDeviceCompatible(_ device: FxADevice) -> Bool {
        guard let marriedState = account.stateCache.value as? MarriedState,
            let availableCommands = device.availableCommands,
            let sendTabCommand = availableCommands[FxACommandSendTab.Name],
            let theirKid = sendTabCommand["kid"].string else {
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
    func encrypt(message: String, device: FxADevice) -> Deferred<Maybe<String>> {
        return account.marriedState() >>== { marriedState in
            guard let bundle = device.availableCommands?[FxACommandSendTab.Name] else {
                return deferMaybe(FxACommandsClientError())
            }

            let syncKeyBundle = KeyBundle.fromKSync(marriedState.kSync)

            guard let cipherdata = bundle["ciphertext"].string?.base64urlSafeDecodedData,
                let iv = bundle["IV"].string?.base64urlSafeDecodedData,
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
        guard let sendTabKeys = self.sendTabKeys,
            let publicKey = sendTabKeys["publicKey"]?.base64urlSafeDecodedData,
            let authSecret = sendTabKeys["authSecret"]?.base64urlSafeDecodedData,
            let cipherdata = ciphertext.base64urlSafeDecodedData,
            let decrypted = try? PushCrypto.sharedInstance.aes128gcm(payload: cipherdata, decryptWith: publicKey, authenticateWith: authSecret) else {
                return nil
        }

        return decrypted.utf8EncodedString
    }

    func generateAndPersistKeys() -> [String : String]? {
        guard let keys = try? PushCrypto.sharedInstance.generateKeys(),
            let publicKey = keys.p256dhPublicKey.utf8EncodedData.base64urlSafeEncodedString,
            let authSecret = keys.auth.utf8EncodedData.base64urlSafeEncodedString else {
                return nil
        }

        let sendTabKeys = [
            "publicKey": publicKey,
            "privateKey": keys.p256dhPrivateKey,
            "authSecret": authSecret
        ]

        // TODO: Save this to keychain (via KeychainCache?)
        self.sendTabKeys = sendTabKeys

        if let prefsBranchPrefix = account.configuration.prefs?.getBranchPrefix() {
            print(prefsBranchPrefix)
        }

        return sendTabKeys
    }

    func getEncryptedKey() -> JSON? {
        guard let sendTabKeys = self.sendTabKeys ?? generateAndPersistKeys(),
            let publicKey = sendTabKeys["publicKey"],
            let authSecret = sendTabKeys["authSecret"],
            let marriedState = account.stateCache.value as? MarriedState else {
            return nil
        }

        let keyToEncrypt = JSON([
            "publicKey": publicKey,
            "authSecret": authSecret
        ])

        let keyBundle = KeyBundle.fromKSync(marriedState.kSync)

        guard let cleartext = try? keyToEncrypt.rawData(options: []),
            let (ciphertext, iv) = keyBundle.encrypt(cleartext) else {
            return nil
        }

        let hmac = keyBundle.hmac(ciphertext)

        guard let ivString = iv.base64urlSafeEncodedString,
            let hmacString = hmac.base64urlSafeEncodedString,
            let ciphertextString = ciphertext.base64urlSafeEncodedString else {
            return nil
        }

        let encryptedKey = JSON([
            "kid": marriedState.kXCS,
            "IV": ivString,
            "hmac": hmacString,
            "ciphertext": ciphertextString
        ])

        return encryptedKey
    }
}
