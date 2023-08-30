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
    var requestStartedWith: String?
    private var completionHandler: (() -> Void)?

    override public var image: UIImage? {
        didSet {
            uniqueID = UUID()
            requestStartedWith = nil
        }
    }
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

    public func setFavicon(_ viewModel: FaviconImageViewModel) {
        setupFaviconLayout(viewModel: viewModel)
        setURL(viewModel)
    }

    // MARK: - SiteImageView

    func setURL(_ viewModel: FaviconImageViewModel) {
        guard canMakeRequest(with: viewModel.siteURLString ?? viewModel.faviconURL?.absoluteString) else { return }

        let id = UUID()
        uniqueID = id

        let model = SiteImageModel(id: id,
                                   expectedImageType: .favicon,
                                   siteURLString: viewModel.siteURLString,
                                   faviconURL: viewModel.faviconURL)
        updateImage(site: model)
    }

    func setImage(imageModel: SiteImageModel) {
        setupFaviconImage(imageModel)
        completionHandler?()
    }

    // MARK: - Favicon

    private func setupFaviconImage(_ viewModel: SiteImageModel) {
        image = viewModel.faviconImage
    }

    private func setupFaviconLayout(viewModel: FaviconImageViewModel) {
        layer.cornerRadius = viewModel.faviconCornerRadius
    }

    private func setupUI() {
        layer.masksToBounds = true
        contentMode = .scaleAspectFit
        clipsToBounds = true
    }
}
