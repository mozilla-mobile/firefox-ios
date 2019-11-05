import Compression
import ARKit

@available(iOS 12.0, *)
extension ARKController {
    
    // MARK: - Saving
    
    /**
     Save the current tracker World Map in local storage
     
     - Fails if tracking isn't initialized, or if the acquisition of a World Map fails for some other reason
     */
    func saveWorldMap() {
        if !trackingStateNormal() {
            print("Can't save WorldMap to local storage until tracking is initialized")
            return
        }
        
        if !worldMappingAvailable() {
            print("Can't save WorldMap to local storage until World Mapping has started")
            return
        }
        
        session.getCurrentWorldMap(completionHandler: { worldMap, error in
            if let worldMap = worldMap {
                print("saving WorldMap to local storage")
                self._save(worldMap)
            } else {
                // try to get rid of an old one if it exists.  Don't care if this fails.
                if let worldSaveURL = self.worldSaveURL {
                    try? FileManager.default.trashItem(at: worldSaveURL, resultingItemURL: nil)
                }
                print("moving saved WorldMap to trash")
            }
        })
    }
    
    func _save(_ worldMap: ARWorldMap) {
        if let worldSaveURL = worldSaveURL {
            var data: Data? = nil
            data = try? NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
            do {
                try data?.write(to: worldSaveURL, options: .atomic)
                print("saved WorldMap to load storage at \(worldSaveURL)")
            } catch {
                print("Failed saving WorldMap to persistent storage")
            }
        }
    }
    
    /**
     Save the current ARKit ARWorldMap if tracking.
     */
    func saveWorldMapInBackground() {
        if !trackingStateNormal() {
            print("can't save WorldMap as we transition to background, tracking isn't initialized")
            return
        }
        
        session.getCurrentWorldMap(completionHandler: { worldMap, error in
            if worldMap != nil {
                print("saving WorldMap as we transition to background")
                self.backgroundWorldMap = worldMap
            }
        })
    }
    
    // MARK: - Loading
    
    /**
     Load a previously saved World Map from local storage.
     */
    func loadSavedMap() {
        if let worldSaveURL = worldSaveURL {
            var data: Data? = nil
            do {
                data = try Data(contentsOf: worldSaveURL)
            } catch {
                print("Error loading WorldMap")
                return
            }
            if let data = data {
                do {
                    guard let obj = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) else {
                        print("Failed to unarchive the WorldMap")
                        return
                    }
                    _setWorldMap(obj)
                } catch {
                    print("Failed to create ARWorldMap from saved WorldMap loaded from persistent storage")
                }
            } else {
                print("Failed to load saved WorldMap from persistent storage")
                return
            }
        }
    }
    
    // MARK: - Getting
    
    /**
     Get the current tracker World Map and return it in an base64 encoded string in a dictionary, for sending to Javascript
     
     - Fails if tracking isn't initialized, or if the acquisition of a World Map fails for some other reason
     
     @param completion The completion block that will be called with the outcome of the acquisition of the world map
     */
    func getWorldMap(_ completion: @escaping GetWorldMapCompletionBlock) {
        if getWorldMapPromise != nil {
            getWorldMapPromise?(false, "World Map request cancelled by subsequent call to get World Map.", nil)
            getWorldMapPromise = nil
        }
        
        #if ALLOW_GET_WORLDMAP
        switch webXRAuthorizationStatus {
        case .worldSensing, .videoCameraAccess:
            getWorldMapPromise = completion
            _getWorldMap()
        case .lite:
            completion(false, "The user only granted access to a single plane, so cannot get map", nil)
        case .minimal, .denied:
            completion(false, "The user denied access to world sensing data", nil)
        case .notDetermined:
            print("Attempt to get World Map but world sensing data authorization is not determined, enqueue the request")
            getWorldMapPromise = completion
        }
        #else
        completion(false, "getWorldMap not supported", nil)
        #endif
    }
    
    // Actually perform the saving and sending of world map back to the app
    func _getWorldMap() {
        let completion: GetWorldMapCompletionBlock? = getWorldMapPromise
        getWorldMapPromise = nil
        
        if configuration is ARFaceTrackingConfiguration {
            if completion != nil {
                completion?(false, "Cannot get World Map when using the front facing camera", nil)
            }
            return
        }
        
        if !trackingStateNormal() {
            if completion != nil {
                completion?(false, "Cannot get World Map until tracking is fully initialized", nil)
            }
            return
        }
        
        if !worldMappingAvailable() {
            if completion != nil {
                completion?(false, "Cannot get World Map until World Mapping has started", nil)
            }
            return
        }
        
        session.getCurrentWorldMap(completionHandler: { worldMap, error in
            if let worldMap = worldMap {
                if let completion = completion {
                    var mapData = [AnyHashable: Any]()
                    
                    var data: Data? = nil
                    do {
                        data = try NSKeyedArchiver.archivedData(withRootObject: worldMap, requiringSecureCoding: true)
                    } catch {
                        print("Error accessing archived worldMap data")
                        return
                    }
                    let compressedData = self.getCompressedData(data)
                    
                    if compressedData == nil {
                        completion(false, "request to get World Map failed: couldn't compress data", nil)
                        return
                    }
                    print("world map uncompressed size \(data?.count ?? 0) -> compressed \(compressedData?.count ?? 0)")
                    
                    let string = compressedData?.base64EncodedString(options: [])
                    mapData["worldMap"] = string ?? ""
                    
                    let anchors = worldMap.anchors
                    let anchorList = NSMutableArray.init(capacity: anchors.count)
                    for anchor in anchors {
                        // include any anchor with a name in the list, since they've likely been
                        // created by the web app
                        if let anchorName = anchor.name {
                            var anchorDict = [AnyHashable : Any]()
                            anchorDict["name"] = anchorName
                            anchorDict["transform"] = anchor.transform.array()
                            anchorList.add(anchorDict)
                        }
                    }
                    mapData["anchors"] = anchorList
                    mapData["center"] = dictFromVector3(worldMap.center)
                    mapData["extent"] = dictFromVector3(worldMap.extent)
                    mapData["featureCount"] = NSNumber(value: worldMap.rawFeaturePoints.points.count)
                    
                    self.printWorldMapInfo(worldMap)
                    
                    completion(true, nil, mapData)
                    print("saving WorldMap due to web request")
                }
            } else {
                if let error = error {
                    completion?(false, "request to get World Map failed: \(error)", nil)
                }
            }
        })
    }
    
    // MARK: - Setting
    
    /**
     Set the current tracker World Map from a base64 encoded text string, passed in from Javascript.
     
     - Fails if the map will not load for some other reason
     
     @param worldMapDictionary The dictionary representing the worldMap
     @param completion The completion block that will be called with the outcome of the loading of the world map
     */
    func setWorldMap(_ worldMapDictionary: [AnyHashable : Any], completion: @escaping SetWorldMapCompletionBlock) {
        if setWorldMapPromise != nil {
            setWorldMapPromise?(false, "World Map set request cancelled by subsequent call to set World Map.")
        }
        
        switch webXRAuthorizationStatus {
        case .worldSensing, .videoCameraAccess:
            setWorldMapPromise = completion
            // we do it here (rather than above) because if a nil is passed in, we don't want to replace the previously saved
            // value (since a user could still reload it with the browser menu)
            let map: ARWorldMap? = dict(toWorldMap: worldMapDictionary)
            
            if let map = map {
                //[self _saveWorldMap:map];
                _setWorldMap(map)
            } else {
                if setWorldMapPromise != nil {
                    setWorldMapPromise?(false, "The World Map may be invalid, it couldn't be decoded.")
                    setWorldMapPromise = nil
                }
            }
        case .lite:
            completion(false, "The user only provided access to a single plane, so cannot set map")
        case .minimal, .denied:
            completion(false, "The user denied access to world sensing data, so cannot set map")
        case .notDetermined:
            print("Attempt to get World Map but world sensing data authorization is not determined, enqueue the request")
            setWorldMapPromise = completion
        }
    }
    
    func _setWorldMap(_ map: ARWorldMap) {
        let completion: SetWorldMapCompletionBlock? = setWorldMapPromise
        setWorldMapPromise = nil
        
        if configuration is ARWorldTrackingConfiguration {
            // First, let's restart with current configuration, but remove existing anchors
            //    [[self session] runWithConfiguration:[self configuration] options: ARSessionRunOptionRemoveExistingAnchors];
            print("Restarted, removing existing anchors")
            
            // now, let's load the world map
            let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
            worldTrackingConfiguration?.initialWorldMap = map
            printWorldMapInfo(map)
            
            session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            
            // if we are removing anchors, clear the user map
            arkitGeneratedAnchorIDUserAnchorIDMap = NSMutableDictionary.init()
            print("Restarted, loading map.")
            
            for anchor in map.anchors {
                session.add(anchor: anchor)
                arkitGeneratedAnchorIDUserAnchorIDMap[anchor.identifier.uuidString] = anchor.name ?? ""
                print("WorldMap loaded anchor: \(anchor.name ?? "nameless anchor")")
            }
            
            // now remove the map from the config
            worldTrackingConfiguration?.initialWorldMap = nil
            
            self.arSessionState = .arkSessionRunning
            // [self setupDeviceCamera];
            
            completion?(true, nil)
            print("using Saved WorldMap to restart session")
        } else {
            print("Cannot load World Map when using user-facing camera")
            completion?(false, "Cannot load World Map when using user-facing camera")
            return
        }
    }
    
    // MARK: - Helpers
    
    func getDecompressedData(_ compressed: Data) -> Data? {
        var dst_buffer_size: size_t = compressed.count * 8
        
        var src_buffer = [UInt8](repeating: 0, count: compressed.count)
        compressed.copyBytes(to: &src_buffer, count: compressed.count)
        
        while true {
            let dst_buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dst_buffer_size)
            let decompressedSize: size_t = compression_decode_buffer(dst_buffer, dst_buffer_size, &src_buffer, compressed.count, nil, COMPRESSION_ZLIB)
            
            // error!
            if decompressedSize == 0 {
                free(dst_buffer)
                return nil
            }
            
            // overflow, try again
            if decompressedSize == dst_buffer_size {
                dst_buffer_size *= 2
                free(dst_buffer)
                continue
            }
            let decompressed = Data(bytes: dst_buffer, count: decompressedSize)
            free(dst_buffer)
            return decompressed
        }
    }
    
    func getCompressedData(_ input: Data?) -> Data? {
        var dst_buffer_size: size_t = max((input?.count ?? 0) / 8, 10)
        
        var src_buffer = [UInt8](repeating: 0, count: input?.count ?? 0)
        input?.copyBytes(to: &src_buffer, count: input?.count ?? 0)
        
        while true {
            let dst_buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dst_buffer_size)
            let compressedSize = compression_encode_buffer(dst_buffer, dst_buffer_size, &src_buffer, (input?.count ?? 0), nil, COMPRESSION_ZLIB)
            
            // overflow, try again
            if compressedSize == 0 {
                dst_buffer_size *= 2
                free(dst_buffer)
                continue
            }
            let compressed = Data(bytes: dst_buffer, count: compressedSize)
            free(dst_buffer)
            return compressed
        }
    }
    
    func printWorldMapInfo(_ worldMap: ARWorldMap) {
        let anchors = worldMap.anchors
        for anchor in anchors {
            var anchorID: String
            if anchor is ARPlaneAnchor {
                // ARKit system plane anchor; probably shouldn't happen!
                anchorID = anchor.identifier.uuidString
                print("saved WorldMap: contained PlaneAnchor")
            } else if anchor is ARImageAnchor {
                // User generated ARImageAnchor; probably shouldn't happen!
                let imageAnchor = anchor as? ARImageAnchor
                anchorID = imageAnchor?.referenceImage.name ?? "No name stored for this imageAnchor's referenceImage"
                print("saved WorldMap: contained trackable ImageAnchor")
            } else if anchor is ARFaceAnchor {
                // System generated ARFaceAnchor; probably shouldn't happen!
                anchorID = anchor.identifier.uuidString
                print("saved WorldMap: contained trackable FaceAnchor")
            } else {
                anchorID = anchor.name ?? "No name stored for this anchor"
            }
            print("WorldMap contains anchor: \(anchorID)")
        }
        let center: simd_float3 = worldMap.center
        let extent: simd_float3 = worldMap.extent
        print("Map center: \(center.x), \(center.y), \(center.z)")
        print("Map extent: \(extent.x), \(extent.y), \(extent.z)")
    }
    
    func dict(toWorldMap worldMapDictionary: [AnyHashable : Any]) -> ARWorldMap? {
        guard let b64String = worldMapDictionary["worldMap"] as? String else { return nil }
        guard let data = Data(base64Encoded: b64String, options: .ignoreUnknownCharacters) else { return nil }
        guard let uncompressed = getDecompressedData(data) else { return nil }
        print("World map compressed size \(data.count) -> uncompressed \(uncompressed.count)")
        var obj: ARWorldMap? = nil
        do {
            obj = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: uncompressed)
        } catch {
            print("Error unarchiving WorldMap")
        }
        
        return obj
    }
    
    func worldMappingAvailable() -> Bool {
        guard let ws = session.currentFrame?.worldMappingStatus else { return false }
        return ws != .notAvailable
    }
    
    /**
     Is there a saved world map?
     */
    func hasBackgroundWorldMap() -> Bool {
        return backgroundWorldMap != nil
    }
}
