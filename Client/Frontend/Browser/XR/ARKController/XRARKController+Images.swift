import Accelerate
import ARKit

@available(iOS 12.0, *)
extension ARKController {
    
    func createReferenceImage(fromDictionary referenceImageDictionary: [AnyHashable: Any]) -> ARReferenceImage? {
        let physicalWidth: CGFloat = referenceImageDictionary["physicalWidth"] as? CGFloat ?? 0
        let b64String = referenceImageDictionary["buffer"] as? String
        let width = size_t(referenceImageDictionary["imageWidth"] as? Int ?? 0)
        let height = size_t(referenceImageDictionary["imageHeight"] as? Int ?? 0)
        let bitsPerComponent: size_t = 8
        let bitsPerPixel: size_t = 32
        let bytesPerRow = size_t(width * 4)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bitmapInfo = CGBitmapInfo(rawValue: 0)
        guard let data = Data(base64Encoded: b64String ?? "", options: .ignoreUnknownCharacters) else { return nil }
        let bridgedData = data as CFData
        guard let dataProvider = CGDataProvider.init(data: bridgedData) else { return nil }
        let shouldInterpolate = true
        
        let cgImage = CGImage(width: width,
                              height: height,
                              bitsPerComponent: bitsPerComponent,
                              bitsPerPixel: bitsPerPixel,
                              bytesPerRow: bytesPerRow,
                              space: colorSpace,
                              bitmapInfo: bitmapInfo,
                              provider: dataProvider,
                              decode: nil,
                              shouldInterpolate: shouldInterpolate,
                              intent: CGColorRenderingIntent.defaultIntent)
        var result: ARReferenceImage? = nil
        if cgImage != nil {
            result = ARReferenceImage(cgImage!, orientation: .up, physicalWidth: physicalWidth)
            result?.name = referenceImageDictionary["uid"] as? String
        }
        
        return result
    }
    
    func createRequestedDetectionImages() {
        for referenceImageDictionary: [AnyHashable : Any] in detectionImageCreationRequests as? [[AnyHashable : Any]] ?? [] {
            _createDetectionImage(referenceImageDictionary)
        }
    }
    
    /**
     If SendWorldSensingDataAuthorizationStateAuthorized, creates an ARImages using the
     information in the dictionary as input. Otherwise, enqueue the request for when the user
     accepts and SendWorldSensingDataAuthorizationStateAuthorized is set
     
     @param referenceImageDictionary the dictionary representing the ARReferenceImage
     @param completion the promise to be resolved when the image is created
     */
    func createDetectionImage(_ referenceImageDictionary: [AnyHashable : Any], completion: @escaping DetectionImageCreatedCompletionType) {
        switch webXRAuthorizationStatus {
        case .lite, .worldSensing, .videoCameraAccess:
            detectionImageCreationPromises[referenceImageDictionary["uid"] as Any] = completion
            _createDetectionImage(referenceImageDictionary)
//        case .lite:
//            completion(false, "The user only provided access to a single plane, not detection images")
        case .minimal, .denied:
            completion(false, "The user denied access to world sensing data")
        case .notDetermined:
            print("Attempt to create a detection image but world sensing data authorization is not determined, enqueue the request")
            detectionImageCreationPromises[referenceImageDictionary["uid"] as Any] = completion
            detectionImageCreationRequests.add(referenceImageDictionary)
        }
    }
    
    func _createDetectionImage(_ referenceImageDictionary: [AnyHashable : Any]) {
        let referenceImage: ARReferenceImage? = createReferenceImage(fromDictionary: referenceImageDictionary)
        let block = detectionImageCreationPromises[referenceImageDictionary["uid"] as Any] as? DetectionImageCreatedCompletionType
        if referenceImage != nil {
            if let referenceImage = referenceImage {
                referenceImageMap[referenceImage.name ?? ""] = referenceImage
            }
            print("Detection image created: \(referenceImage?.name ?? "")")
            
            if block != nil {
                block?(true, nil)
            }
        } else {
            print("Cannot create detection image from dictionary: \(String(describing: referenceImageDictionary["uid"]))")
            if block != nil {
                block?(false, "Error creating the ARReferenceImage")
            }
        }
        
        detectionImageCreationPromises[referenceImageDictionary["uid"] as Any] = nil
    }
    
    /**
     Adds the image to the set of references images in the configuration object and re-runs the session.
     
     - If the image hasn't been created, it calls the promise with an error string.
     - It also fails when the current session is not of type ARWorldTrackingConfiguration
     - If the image trying to be activated was already activated but not yet detected, respond with an error string in the callback
     - If the image trying to be activated was already activated and yet detected, we remove it from the session, so
     it can be detected again by ARKit
     
     @param imageName the name of the image to be added to the session. It must have been previously created with createImage
     @param completion a completion block acting a promise
     */
    func activateDetectionImage(_ imageName: String?, completion: @escaping ActivateDetectionImageCompletionBlock) {
        if configuration is ARFaceTrackingConfiguration {
            completion(false, "Cannot activate a detection image when using the front facing camera", nil)
            return
        }
        
        let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
        if let referenceImage = referenceImageMap[imageName ?? ""] as? ARReferenceImage {
            var currentDetectionImages = worldTrackingConfiguration?.detectionImages != nil ? worldTrackingConfiguration?.detectionImages : Set<AnyHashable>()
            if !(currentDetectionImages?.contains(referenceImage) ?? false) {
                _ = currentDetectionImages?.insert(referenceImage)
                if let currentDetectionImages = currentDetectionImages as? Set<ARReferenceImage> {
                    worldTrackingConfiguration?.detectionImages = currentDetectionImages
                }
                
                detectionImageActivationPromises[referenceImage.name ?? ""] = completion
                session.run(configuration, options: [])
            } else {
                if detectionImageActivationPromises[referenceImage.name ?? ""] != nil {
                    // Trying to reactivate an active image that hasn't been found yet, return an error on the first promise, keep the second
                    let activationBlock = detectionImageActivationPromises[referenceImage.name ?? ""] as? ActivateDetectionImageCompletionBlock
                    activationBlock?(false, "Image reactived, only can have one active at a time", nil)
                    detectionImageActivationAfterRemovalPromises[referenceImage.name ?? ""] = completion
                    return
                } else {
                    // Activating an already activated and found image, remove the anchor from the scene
                    // so it can be detected again
                    guard let anchors = session.currentFrame?.anchors else { return }
                    for anchor in anchors {
                        if let imageAnchor = anchor as? ARImageAnchor,
                            imageAnchor.referenceImage.name == imageName
                        {
                            // Remove the reference image from the session configuration and run again
                            currentDetectionImages?.remove(referenceImage)
                            if let currentDetectionImages = currentDetectionImages as? Set<ARReferenceImage> {
                                worldTrackingConfiguration?.detectionImages = currentDetectionImages
                            }
                            session.run(configuration, options: [])
                            
                            // When the anchor is removed and didRemoveAnchor callback gets called, look in this map
                            // and see if there is a promise for the recently removed image anchor. If so, call
                            // activateDetectionImage again with the image name of the removed anchor, and the completion set here
                            detectionImageActivationAfterRemovalPromises[referenceImage.name ?? ""] = completion
                            session.remove(anchor: anchor)
                            return
                        }
                    }
                }
            }
        } else {
            completion(false, "The image \(imageName ?? "") doesn't exist", nil)
        }
    }
    
    /**
     Removes the reference image from the current set of reference images and re-runs the session
     
     - It fails when the current session is not of type ARWorldTrackingConfiguration
     - It fails when the image trying to be deactivated is not in the current set of detection images
     - It fails when the image trying to be deactivated was already detected
     - It fails when the image trying to be deactivated is still active
     
     @param imageName The name of the image to be deactivated
     @param completion The promise that will be called with the outcome of the deactivation
     */
    func deactivateDetectionImage(_ imageName: String, completion: DetectionImageCreatedCompletionType) {
        if configuration is ARFaceTrackingConfiguration {
            completion(false, "Cannot deactivate a detection image when using the front facing camera")
            return
        }
        
        let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
        let referenceImage = referenceImageMap[imageName] as? ARReferenceImage
        
        var currentDetectionImages = worldTrackingConfiguration?.detectionImages != nil ? worldTrackingConfiguration?.detectionImages : Set<AnyHashable>()
        if let referenceImage = referenceImage {
            if currentDetectionImages?.contains(referenceImage) ?? false {
                if detectionImageActivationPromises[referenceImage.name ?? ""] != nil {
                    // The image trying to be deactivated hasn't been found yet, return an error on the activation block and remove it
                    let activationBlock = detectionImageActivationPromises[referenceImage.name ?? ""] as? ActivateDetectionImageCompletionBlock
                    activationBlock?(false, "The image has been deactivated", nil)
                    detectionImageActivationPromises[referenceImage.name ?? ""] = nil
                }
                
                // remove the image from the set being searched for
                currentDetectionImages?.remove(referenceImage)
                if let currentDetectionImages = currentDetectionImages as? Set<ARReferenceImage> {
                    worldTrackingConfiguration?.detectionImages = currentDetectionImages
                }
                session.run(configuration, options: [])
                completion(true, nil)
            } else {
                completion(false, "The image attempting to be deactivated doesn't exist")
            }
        }
    }
    
    /**
     Destroys the detection image
     
     - Fails if the image to be destroy doesn't exist
     
     @param imageName The name of the image to be destroyed
     @param completion The completion block that will be called with the outcome of the destroy
     */
    func destroyDetectionImage(_ imageName: String, completion: DetectionImageCreatedCompletionType) {
        let referenceImage = referenceImageMap[imageName] as? ARReferenceImage
        if let referenceImage = referenceImage {

            // images can only be active in WorldTrackingConfiguration
            if configuration is ARWorldTrackingConfiguration {
                
                // let's see if it's active, and if so deactivate
                let worldTrackingConfiguration = configuration as? ARWorldTrackingConfiguration
                var currentDetectionImages = worldTrackingConfiguration?.detectionImages != nil ? worldTrackingConfiguration?.detectionImages : Set<AnyHashable>()
                
                if currentDetectionImages?.contains(referenceImage) ?? false {
                    // The image trying to be deactivated hasn't been found yet, return an error on the activation block and remove it
                    if (detectionImageActivationPromises[referenceImage.name ?? ""] != nil) {
                        let activationBlock = detectionImageActivationPromises[referenceImage.name ?? ""] as? ActivateDetectionImageCompletionBlock
                        activationBlock?(false, "The image has been deactivated and destroyed", nil)
                        detectionImageActivationPromises[referenceImage.name ?? ""] = nil
                    }

                    // remove the image from the set being searched for
                    currentDetectionImages?.remove(referenceImage)
                    if let currentDetectionImages = currentDetectionImages as? Set<ARReferenceImage> {
                        worldTrackingConfiguration?.detectionImages = currentDetectionImages
                    }
                    session.run(configuration, options: [])
                }
            }
            referenceImageMap[imageName] = nil

            completion(true, nil)
        } else {
            completion(false, "The image doesn't exist")
        }
    }
    
    func clearImageDetectionDictionaries() {
        detectionImageActivationPromises.removeAllObjects()
        referenceImageMap.removeAllObjects()
        detectionImageCreationRequests.removeAllObjects()
        detectionImageCreationPromises.removeAllObjects()
        detectionImageActivationAfterRemovalPromises.removeAllObjects()
    }
    
    // MARK: - Buffer Functions
    
    func updateBase64Buffers(from capturedImagePixelBuffer: CVPixelBuffer) {
        
        // Luma
        CVPixelBufferLockBaseAddress(capturedImagePixelBuffer, CVPixelBufferLockFlags.readOnly)
        
        //[self logPixelBufferInfo:capturedImagePixelBuffer];
        
        let lumaBufferWidth: size_t = CVPixelBufferGetWidthOfPlane(capturedImagePixelBuffer, 0)
        let lumaBufferHeight: size_t = CVPixelBufferGetHeightOfPlane(capturedImagePixelBuffer, 0)
        
        var lumaSrcBuffer = vImage_Buffer()
        lumaSrcBuffer.data = CVPixelBufferGetBaseAddressOfPlane(capturedImagePixelBuffer, 0)
        lumaSrcBuffer.width = vImagePixelCount(lumaBufferWidth)
        lumaSrcBuffer.height = vImagePixelCount(lumaBufferHeight)
        lumaSrcBuffer.rowBytes = CVPixelBufferGetBytesPerRowOfPlane(capturedImagePixelBuffer, 0)
        
        var extraColumnsOnLeft = size_t()
        var extraColumnsOnRight = size_t()
        var extraColumnsOnTop = size_t()
        var extraColumnsOnBottom = size_t()
        CVPixelBufferGetExtendedPixels(capturedImagePixelBuffer, &extraColumnsOnLeft, &extraColumnsOnRight, &extraColumnsOnTop, &extraColumnsOnBottom)
        
        if lumaBufferSize.width == 0.0 {
            lumaBufferSize = downscaleByFactorOf2(untilLargestSideIsLessThan512AvoidingFractionalSides: CGSize(width: CGFloat(lumaBufferWidth), height: CGFloat(lumaBufferHeight)))
        }
        chromaBufferSize = CGSize(width: lumaBufferSize.width / 2.0, height: lumaBufferSize.height / 2.0)
        
        if lumaBuffer.data == nil {
            vImageBuffer_Init(&lumaBuffer, vImagePixelCount(lumaBufferSize.height), vImagePixelCount(lumaBufferSize.width), UInt32(8 * MemoryLayout<Pixel_8>.size), vImage_Flags(kvImageNoFlags))
            vImageScale_Planar8(&lumaBuffer, &lumaBuffer, nil, vImage_Flags(kvImageGetTempBufferSize))
            let scaledBufferSize: size_t = vImageScale_Planar8(&lumaSrcBuffer, &lumaBuffer, nil, vImage_Flags(kvImageGetTempBufferSize))
            lumaScaleTemporaryBuffer = malloc(scaledBufferSize * MemoryLayout<Pixel_8>.size)
        }
        
        var scaleError: vImage_Error = vImageScale_Planar8(&lumaSrcBuffer, &lumaBuffer, lumaScaleTemporaryBuffer, vImage_Flags(kvImageNoFlags))
        if scaleError != 0 {
            print("Error scaling luma image")
            CVPixelBufferUnlockBaseAddress(capturedImagePixelBuffer, CVPixelBufferLockFlags.readOnly)
            return
        }

        if lumaDataBuffer == nil {
            lumaDataBuffer = NSMutableData(bytes: lumaBuffer.data,
                                           length: Int(lumaBuffer.width * lumaBuffer.height) * MemoryLayout<Pixel_8>.size)
        }
        for currentRow in 0..<Int(lumaBuffer.height) {
            lumaDataBuffer?.replaceBytes(in: NSRange(location: Int(lumaBuffer.width) * currentRow, length: Int(lumaBuffer.width)), withBytes: lumaBuffer.data + lumaBuffer.rowBytes * currentRow)
        }
        
        if let stringBuffer = lumaDataBuffer?.base64EncodedString(options: []) as? NSMutableString {
            lumaBase64StringBuffer = stringBuffer as String
        }
        
        // Chroma
        var chromaSrcBuffer = vImage_Buffer()
        chromaSrcBuffer.data = CVPixelBufferGetBaseAddressOfPlane(capturedImagePixelBuffer, 1)
        chromaSrcBuffer.width = vImagePixelCount(CVPixelBufferGetWidthOfPlane(capturedImagePixelBuffer, 1))
        chromaSrcBuffer.height = vImagePixelCount(CVPixelBufferGetHeightOfPlane(capturedImagePixelBuffer, 1))
        chromaSrcBuffer.rowBytes = CVPixelBufferGetBytesPerRowOfPlane(capturedImagePixelBuffer, 1)
        
        if chromaBuffer.data == nil {
            vImageBuffer_Init(&chromaBuffer, vImagePixelCount(chromaBufferSize.height), vImagePixelCount(chromaBufferSize.width), UInt32(8 * MemoryLayout<Pixel_16U>.size), vImage_Flags(kvImageNoFlags))
            let scaledBufferSize: size_t = vImageScale_Planar8(&chromaSrcBuffer, &chromaBuffer, nil, vImage_Flags(kvImageGetTempBufferSize))
            chromaScaleTemporaryBuffer = malloc(scaledBufferSize * MemoryLayout<Pixel_16U>.size)
        }
        
        scaleError = vImageScale_CbCr8(&chromaSrcBuffer, &chromaBuffer, chromaScaleTemporaryBuffer, vImage_Flags(kvImageNoFlags))
        if scaleError != 0 {
            print("Error scaling chroma image")
            CVPixelBufferUnlockBaseAddress(capturedImagePixelBuffer, CVPixelBufferLockFlags.readOnly)
            return
        }

        if chromaDataBuffer == nil {
            chromaDataBuffer = NSMutableData(bytes: chromaBuffer.data,
                                             length: Int(chromaBuffer.width * chromaBuffer.height) * MemoryLayout<Pixel_16U>.size)
        }
        for currentRow in 0..<Int(chromaBuffer.height) {
            chromaDataBuffer?.replaceBytes(in: NSRange(location: Int(chromaBuffer.width) * currentRow * MemoryLayout<Pixel_16U>.size, length: Int(chromaBuffer.width) * MemoryLayout<Pixel_16U>.size), withBytes: chromaBuffer.data + chromaBuffer.rowBytes * currentRow)
        }
        
        if let chromaStringBuffer = chromaDataBuffer?.base64EncodedString(options: []) as? NSMutableString {
            chromaBase64StringBuffer = chromaStringBuffer as String
        }
        
        CVPixelBufferUnlockBaseAddress(capturedImagePixelBuffer, CVPixelBufferLockFlags.readOnly)
    }
    
    func downscaleByFactorOf2(untilLargestSideIsLessThan512AvoidingFractionalSides originalSize: CGSize) -> CGSize {
        var result: CGSize = originalSize
        
        var largestSideLessThan512Found = false
        var fractionalSideFound = false
        computerVisionImageScaleFactor = 1.0
        while !(largestSideLessThan512Found || fractionalSideFound) {
            if Int(result.width) % 2 != 0 || Int(result.height) % 2 != 0 {
                fractionalSideFound = true
            } else {
                result = CGSize(width: result.width / 2.0, height: result.height / 2.0)
                computerVisionImageScaleFactor *= 2.0
                
                let largestSide = max(result.width, result.height)
                if largestSide < 512 {
                    largestSideLessThan512Found = true
                }
            }
        }
        
        return result
    }
    
    func string(for type: OSType) -> String {
        
        switch type {
        case kCVPixelFormatType_1Monochrome:                return "kCVPixelFormatType_1Monochrome"
        case kCVPixelFormatType_2Indexed:                   return "kCVPixelFormatType_2Indexed"
        case kCVPixelFormatType_4Indexed:                   return "kCVPixelFormatType_4Indexed"
        case kCVPixelFormatType_8Indexed:                   return "kCVPixelFormatType_8Indexed"
        case kCVPixelFormatType_1IndexedGray_WhiteIsZero:   return "kCVPixelFormatType_1IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_2IndexedGray_WhiteIsZero:   return "kCVPixelFormatType_2IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_4IndexedGray_WhiteIsZero:   return "kCVPixelFormatType_4IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_8IndexedGray_WhiteIsZero:   return "kCVPixelFormatType_8IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_16BE555:                    return "kCVPixelFormatType_16BE555"
        case kCVPixelFormatType_16LE555:                    return "kCVPixelFormatType_16LE555"
        case kCVPixelFormatType_16LE5551:                   return "kCVPixelFormatType_16LE5551"
        case kCVPixelFormatType_16BE565:                    return "kCVPixelFormatType_16BE565"
        case kCVPixelFormatType_16LE565:                    return "kCVPixelFormatType_16LE565"
        case kCVPixelFormatType_24RGB:                      return "kCVPixelFormatType_24RGB"
        case kCVPixelFormatType_24BGR:                      return "kCVPixelFormatType_24BGR"
        case kCVPixelFormatType_32ARGB:                     return "kCVPixelFormatType_32ARGB"
        case kCVPixelFormatType_32BGRA:                     return "kCVPixelFormatType_32BGRA"
        case kCVPixelFormatType_32ABGR:                     return "kCVPixelFormatType_32ABGR"
        case kCVPixelFormatType_32RGBA:                     return "kCVPixelFormatType_32RGBA"
        case kCVPixelFormatType_64ARGB:                     return "kCVPixelFormatType_64ARGB"
        case kCVPixelFormatType_48RGB:                      return "kCVPixelFormatType_48RGB"
        case kCVPixelFormatType_32AlphaGray:                return "kCVPixelFormatType_32AlphaGray"
        case kCVPixelFormatType_16Gray:                     return "kCVPixelFormatType_16Gray"
        case kCVPixelFormatType_30RGB:                      return "kCVPixelFormatType_30RGB"
        case kCVPixelFormatType_422YpCbCr8:                 return "kCVPixelFormatType_422YpCbCr8"
        case kCVPixelFormatType_4444YpCbCrA8:               return "kCVPixelFormatType_4444YpCbCrA8"
        case kCVPixelFormatType_4444YpCbCrA8R:              return "kCVPixelFormatType_4444YpCbCrA8R"
        case kCVPixelFormatType_4444AYpCbCr8:               return "kCVPixelFormatType_4444AYpCbCr8"
        case kCVPixelFormatType_4444AYpCbCr16:              return "kCVPixelFormatType_4444AYpCbCr16"
        case kCVPixelFormatType_444YpCbCr8:                 return "kCVPixelFormatType_444YpCbCr8"
        case kCVPixelFormatType_422YpCbCr16:                return "kCVPixelFormatType_422YpCbCr16"
        case kCVPixelFormatType_422YpCbCr10:                return "kCVPixelFormatType_422YpCbCr10"
        case kCVPixelFormatType_444YpCbCr10:                return "kCVPixelFormatType_444YpCbCr10"
        case kCVPixelFormatType_420YpCbCr8Planar:           return "kCVPixelFormatType_420YpCbCr8Planar"
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:  return "kCVPixelFormatType_420YpCbCr8PlanarFullRange"
        case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:     return "kCVPixelFormatType_422YpCbCr_4A_8BiPlanar"
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:   return "kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange"
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:    return "kCVPixelFormatType_420YpCbCr8BiPlanarFullRange"
        case kCVPixelFormatType_422YpCbCr8_yuvs:            return "kCVPixelFormatType_422YpCbCr8_yuvs"
        case kCVPixelFormatType_422YpCbCr8FullRange:        return "kCVPixelFormatType_422YpCbCr8FullRange"
        case kCVPixelFormatType_OneComponent8:              return "kCVPixelFormatType_OneComponent8"
        case kCVPixelFormatType_TwoComponent8:              return "kCVPixelFormatType_TwoComponent8"
        case kCVPixelFormatType_30RGBLEPackedWideGamut:     return "kCVPixelFormatType_30RGBLEPackedWideGamut"
        case kCVPixelFormatType_OneComponent16Half:         return "kCVPixelFormatType_OneComponent16Half"
        case kCVPixelFormatType_OneComponent32Float:        return "kCVPixelFormatType_OneComponent32Float"
        case kCVPixelFormatType_TwoComponent16Half:         return "kCVPixelFormatType_TwoComponent16Half"
        case kCVPixelFormatType_TwoComponent32Float:        return "kCVPixelFormatType_TwoComponent32Float"
        case kCVPixelFormatType_64RGBAHalf:                 return "kCVPixelFormatType_64RGBAHalf"
        case kCVPixelFormatType_128RGBAFloat:               return "kCVPixelFormatType_128RGBAFloat"
        case kCVPixelFormatType_14Bayer_GRBG:               return "kCVPixelFormatType_14Bayer_GRBG"
        case kCVPixelFormatType_14Bayer_RGGB:               return "kCVPixelFormatType_14Bayer_RGGB"
        case kCVPixelFormatType_14Bayer_BGGR:               return "kCVPixelFormatType_14Bayer_BGGR"
        case kCVPixelFormatType_14Bayer_GBRG:               return "kCVPixelFormatType_14Bayer_GBRG"
        default:                                            return "UNKNOWN"
        }
    }
    
    func logPixelBufferInfo(_ capturedImagePixelBuffer: CVPixelBuffer) {
        let capturedImagePixelBufferWidth = CVPixelBufferGetWidth(capturedImagePixelBuffer)
        let capturedImagePixelBufferHeight = CVPixelBufferGetHeight(capturedImagePixelBuffer)
        let capturedImagePixelBufferBytesPerRow = CVPixelBufferGetBytesPerRow(capturedImagePixelBuffer)
        let capturedImageNumberOfPlanes = CVPixelBufferGetPlaneCount(capturedImagePixelBuffer)
        let capturedImagePixelBufferTypeID = CVPixelBufferGetTypeID()
        let capturedImagePixelBufferDataSize = CVPixelBufferGetDataSize(capturedImagePixelBuffer)
        let capturedImagePixelBufferPixelFormatType: OSType = CVPixelBufferGetPixelFormatType(capturedImagePixelBuffer)
        let capturedImagePixelBufferBaseAddress = CVPixelBufferGetBaseAddress(capturedImagePixelBuffer)
        
        print("\n\nnumberOfPlanes: \(capturedImageNumberOfPlanes)\npixelBufferWidth: \(capturedImagePixelBufferWidth)\npixelBufferHeight: \(capturedImagePixelBufferHeight)\npixelBufferTypeID: \(capturedImagePixelBufferTypeID)\npixelBufferDataSize: \(capturedImagePixelBufferDataSize)\npixelBufferBytesPerRow: \(capturedImagePixelBufferBytesPerRow)\npixelBufferPIxelFormatType:" + string(for: capturedImagePixelBufferPixelFormatType) + "\npixelBufferBaseAddress: \(String(describing: capturedImagePixelBufferBaseAddress))\n")
    }
    
    // MARK: - Helpers
    
    func setNumberOfTrackedImages(_ numberOfTrackedImages: Int) {
        if let trackingConfiguration = configuration as? ARWorldTrackingConfiguration {
            trackingConfiguration.maximumNumberOfTrackedImages = numberOfTrackedImages
            session.run(trackingConfiguration, options: [])
        } else {
            print("Error: Cannot set tracked images on an ARFaceTrackingConfiguration session.")
        }
    }
}
