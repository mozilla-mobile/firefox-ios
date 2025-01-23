// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// FaviconImageView supports the favicon image layout.
/// By setting the view model, the image will be updated for you asynchronously
///
/// - Favicon
///     - Can be set through `setFavicon(_ viewModel: SiteImageViewFaviconModel)`
///     - No theming calls needed
public class FaviconImageView: UIImageView, SiteImageView {
    // MARK: - Properties
    var uniqueID: UUID?
    var imageFetcher: SiteImageHandler
    var currentURLString: String?
    private var completionHandler: (() -> Void)?

    // MARK: - Init

    override public init(frame: CGRect) {
        self.imageFetcher = DefaultSiteImageHandler()
        super.init(frame: frame)
        setupUI()
    }

    // Internal init used in unit tests only
    init(frame: CGRect,
         imageFetcher: SiteImageHandler,
         completionHandler: @escaping () -> Void) {
        self.imageFetcher = imageFetcher
        self.completionHandler = completionHandler
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public

    /// Initiates the retrival of the favion image and sets it to the view
    /// - Parameter viewModel: the configuration of the favicon
    public func setFavicon(_ viewModel: FaviconImageViewModel) {
        setupFaviconLayout(viewModel: viewModel)
        setURL(viewModel)
    }

    /// Manually set the image for the favicon view
    /// - Parameter image: the image to be set on the view
    public func manuallySetImage(_ image: UIImage) {
        uniqueID = UUID()
        currentURLString = nil
        self.image = image
    }

    // MARK: - SiteImageView

    func setURL(_ viewModel: FaviconImageViewModel) {
        guard let siteURLString = viewModel.siteURLString,
              let siteURL = URL(string: siteURLString, invalidCharacters: false),
              canMakeRequest(with: siteURLString)
        else { return }

        // If a new request is being made on an existing image it is likely a cell or view being reused.
        // Continuing to display the previous image in this case would never be desired so reset to nil
        image = nil
        backgroundColor = .clear

        let id = UUID()
        uniqueID = id
        currentURLString = siteURLString

        let model = SiteImageModel(id: id,
                                   imageType: .favicon,
                                   siteURL: siteURL,
                                   siteResource: viewModel.siteResource)
        updateImage(model: model)
    }

    func setImage(image: UIImage) {
        self.image = image
        completionHandler?()
    }

    // MARK: - Favicon

    private func setupFaviconLayout(viewModel: FaviconImageViewModel) {
        layer.cornerRadius = viewModel.faviconCornerRadius
    }

    private func setupUI() {
        layer.masksToBounds = true
        contentMode = .scaleAspectFit
        clipsToBounds = true
    }
}
