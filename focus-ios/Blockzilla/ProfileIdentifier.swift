// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/


import Foundation
import Glean

// MARK: - ProfileIdentifier Implementation

class ProfileIdentifier {
    struct Constants {
        static let profileIdKey = "profileId"
        static let canaryUUID = UUID(uuidString: "beefbeef-beef-beef-beef-beeefbeefbee")!
        static let fileName = "profile_identifier.txt"
    }
    
    // File URL for backup storage
    private var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(Constants.profileIdKey)
    }
    
    // Clear the profile ID from all storage locations
    func unsetUsageProfileId() {
        // Clear from UserDefaults
        UserDefaults.standard.removeObject(forKey: Constants.profileIdKey)
        
        // Clear from file backup
        try? FileManager.default.removeItem(at: fileURL)
        
        // Set canary UUID in metrics
        GleanMetrics.Usage.profileId.set(Constants.canaryUUID)
    }
    
    // Check and set the profile ID from available storage locations
    func checkAndSetProfileId() {
        // Try to get from UserDefaults first
        if let uuidFromDefaults = getProfileIdFromUserDefaults() {
            // Found in UserDefaults, use it and ensure backup exists
            useAndBackupProfileId(uuidFromDefaults)
            return
        }
        
        // Try to get from file backup
        if let uuidFromFile = getProfileIdFromFile() {
            // Found in file, use it and ensure it's in UserDefaults
            useAndBackupProfileId(uuidFromFile)
            return
        }
        
        // No ID found, generate a new one and store it everywhere
        let newUUID = GleanMetrics.Usage.profileId.generateAndSet()
        storeProfileId(newUUID)
    }
    
    // Helper to retrieve UUID from UserDefaults
    private func getProfileIdFromUserDefaults() -> UUID? {
        guard let uuidString = UserDefaults.standard.string(forKey: Constants.profileIdKey),
              let uuid = UUID(uuidString: uuidString) else {
            return nil
        }
        return uuid
    }
    
    // Helper to retrieve UUID from file backup
    private func getProfileIdFromFile() -> UUID? {
        do {
            let data = try Data(contentsOf: fileURL)
            if let uuidString = String(data: data, encoding: .utf8),
               let uuid = UUID(uuidString: uuidString) {
                return uuid
            }
        } catch {
            // File doesn't exist or couldn't be read
            return nil
        }
        return nil
    }
    
    // Store UUID in all locations
    private func storeProfileId(_ uuid: UUID) {
        // Store in UserDefaults
        UserDefaults.standard.set(uuid.uuidString, forKey: Constants.profileIdKey)
        
        // Store in file backup
        do {
            try uuid.uuidString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write UUID to file: \(error)")
        }
        
        // Set in metrics
        GleanMetrics.Usage.profileId.set(uuid)
    }
    
    // Use an existing UUID and ensure it's backed up everywhere
    private func useAndBackupProfileId(_ uuid: UUID) {
        storeProfileId(uuid)
    }
}
