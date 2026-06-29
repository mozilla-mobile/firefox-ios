// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol GoogleLensServicing {
    /// Preprocesses `image` and builds the Google Lens upload request for it.
    /// - Parameter viewportSize: the size Lens should render its result UI for.
    /// - Returns: the upload request, or `nil` if the image could not be processed.
    func makeUploadRequest(for image: UIImage, viewportSize: CGSize) -> URLRequest?
}

/// Produces the Google Lens upload request for an image by composing the image
/// processor and the request builder.
struct GoogleLensService: GoogleLensServicing {
    private let imageProcessor: GoogleLensImageProcessing
    private let requestBuilder: GoogleLensRequestBuilding

    init(imageProcessor: GoogleLensImageProcessing = GoogleLensImageProcessor(),
         requestBuilder: GoogleLensRequestBuilding = GoogleLensRequestBuilder()) {
        self.imageProcessor = imageProcessor
        self.requestBuilder = requestBuilder
    }

    func makeUploadRequest(for image: UIImage, viewportSize: CGSize) -> URLRequest? {
        guard let processedImage = imageProcessor.process(image) else { return nil }
        let input = GoogleLensUploadInput(jpegData: processedImage.jpegData,
                                          imageDimensions: processedImage.dimensions,
                                          viewportSize: viewportSize)
        return requestBuilder.makeUploadRequest(for: input)
    }
}
