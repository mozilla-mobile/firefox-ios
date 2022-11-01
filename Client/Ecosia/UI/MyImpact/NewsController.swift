/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class NewsController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout, NotificationThemeable {
    private weak var collection: UICollectionView!
    private var items = [NewsModel]()
    private let images = Images(.init(configuration: .ephemeral))
    private let news = News()
    private let identifier = "news"
    var delegate: EcosiaHomeDelegate?

    required init?(coder: NSCoder) { nil }

    init(items: [NewsModel], delegate: EcosiaHomeDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.items = items
        title = .localized(.stories)
        navigationItem.largeTitleDisplayMode = .always
    }
    
    override func loadView() {
        let flow = UICollectionViewFlowLayout()
        flow.minimumInteritemSpacing = 0
        flow.minimumLineSpacing = 0
        flow.estimatedItemSize = UICollectionViewFlowLayout.automaticSize

        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
        collection.delegate = self
        collection.dataSource = self
        collection.register(NewsCell.self, forCellWithReuseIdentifier: identifier)
        collection.register(NewsSubHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: identifier)
        collection.backgroundView = indicator
        collection.contentInsetAdjustmentBehavior = .scrollableAxes
        self.collection = collection
        view = collection
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        news.subscribe(self) { [weak self] in
            self?.items = $0
            self?.collection.reloadData()
            self?.collection.backgroundView = nil
        }

        let done = UIBarButtonItem(barButtonSystemItem: .done) { [ weak self ] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        navigationItem.rightBarButtonItem = done

        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        news.load(session: .shared)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Analytics.shared.navigation(.view, label: .news)
    }
    
    override func viewWillTransition(to: CGSize, with: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: to, with: with)
        collection?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_: UICollectionView, numberOfItemsInSection: Int) -> Int {
        items.count
    }
    
    func collectionView(_: UICollectionView, viewForSupplementaryElementOfKind kind: String, at: IndexPath) -> UICollectionReusableView {
        let header = collection.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: at)
        collection.align(header: header as? NewsSubHeader)
        return header
    }
    
    func collectionView(_: UICollectionView, cellForItemAt: IndexPath) -> UICollectionViewCell {
        let cell = collection.dequeueReusableCell(withReuseIdentifier: identifier, for: cellForItemAt) as! NewsCell
        cell.configure(items[cellForItemAt.row], images: images, positions: .derive(row: cellForItemAt.item, items: items.count))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt: IndexPath) -> CGSize {
        return .init(width: collection.ecosiaHomeMaxWidth, height: 130)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        
        collectionView.align(
            header: collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader,
            at: .init(item: 0, section: section)) as? NewsSubHeader)
        
        return .init(width: 0, height: UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body).pointSize * 2 + 30)
    }
    
    func collectionView(_: UICollectionView, didSelectItemAt: IndexPath) {
        let item = items[didSelectItemAt.row]
        delegate?.ecosiaHome(didSelectURL: item.targetUrl)
        dismiss(animated: true, completion: nil)
        Analytics.shared.navigationOpenNews(item.trackingName)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, insetForSectionAt: Int) -> UIEdgeInsets {
        let horizontal = (collectionView.bounds.width - collectionView.ecosiaHomeMaxWidth) / 2
        return .init(top: 0, left: horizontal, bottom: 0, right: horizontal)
    }

    func applyTheme() {
        collection.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).forEach({
            ($0 as? NotificationThemeable)?.applyTheme()
        })
        collection.visibleCells.forEach({
            ($0 as? NotificationThemeable)?.applyTheme()
        })
        collection.backgroundColor = UIColor.theme.ecosia.modalBackground
        updateBarAppearance()

        if traitCollection.userInterfaceIdiom == .pad {
            let margin = max((view.bounds.width - 544) / 2.0, 0)
            additionalSafeAreaInsets = .init(top: 0, left: margin, bottom: 0, right: margin)
        }
    }

    private func updateBarAppearance() {
        guard let appearance = navigationController?.navigationBar.standardAppearance else { return }
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.theme.ecosia.primaryText]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.theme.ecosia.primaryText]
        appearance.backgroundColor = .theme.ecosia.modalBackground
        navigationItem.standardAppearance = appearance
        navigationController?.navigationBar.backgroundColor = .theme.ecosia.modalBackground
        navigationController?.navigationBar.tintColor = .theme.ecosia.primaryBrand
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyTheme()
    }
}

private extension UICollectionView {
    func align(header: NewsSubHeader?) {
        let margin = (bounds.width - ecosiaHomeMaxWidth) / 2
        header?.leftMargin.constant = margin
        header?.rightMargin.constant = -margin
    }
}

private final class NewsSubHeader: UICollectionReusableView, NotificationThemeable {
    private(set) weak var leftMargin: NSLayoutConstraint!
    private(set) weak var rightMargin: NSLayoutConstraint!
    private weak var subtitle: UILabel!
    
    required init?(coder: NSCoder) { nil }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.adjustsFontSizeToFitWidth = true
        subtitle.setContentHuggingPriority(.required, for: .vertical)
        subtitle.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        subtitle.numberOfLines = 2
        subtitle.text = .localized(.keepUpToDate)
        addSubview(subtitle)
        self.subtitle = subtitle
        
        subtitle.topAnchor.constraint(equalTo: topAnchor, constant: 0).isActive = true
        subtitle.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -10).isActive = true
        
        leftMargin = subtitle.leftAnchor.constraint(equalTo: leftAnchor)
        leftMargin.isActive = true
        rightMargin = subtitle.rightAnchor.constraint(lessThanOrEqualTo: rightAnchor)
        rightMargin.isActive = true

        applyTheme()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        backgroundColor = UIColor.theme.ecosia.modalBackground
        subtitle.textColor = UIColor.theme.ecosia.secondaryText
    }
}
