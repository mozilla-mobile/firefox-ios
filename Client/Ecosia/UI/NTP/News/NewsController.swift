/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class NewsController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout, NotificationThemeable {
    private weak var collection: UICollectionView!
    private var items = [NewsCell.ViewModel]()
    private let images = Images(.init(configuration: .ephemeral))
    private let news = News()
    private let identifier = "news"
    var delegate: YourImpactDelegate?

    required init?(coder: NSCoder) { nil }

    init(items: [NewsCell.ViewModel], delegate: YourImpactDelegate?) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.items = items
        title = .localized(.stories)
        navigationItem.largeTitleDisplayMode = .always
    }
    
    override func loadView() {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.startAnimating()
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collection.delegate = self
        collection.dataSource = self
        collection.register(NewsCell.self, forCellWithReuseIdentifier: identifier)
        collection.register(NewsSubHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: identifier)
        collection.backgroundView = indicator
        collection.contentInsetAdjustmentBehavior = .scrollableAxes
        self.collection = collection
        view = collection
    }

    func createLayout() -> UICollectionViewLayout {

        let layout = UICollectionViewCompositionalLayout { [weak self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

            guard let self = self else { return nil }

            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                  heightDimension: .estimated(100))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                   heightDimension: .estimated(100))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

            let section = NSCollectionLayoutSection(group: group)

            let horizontal = (self.collection.bounds.width - self.collection.yourImpactMaxWidth) / 2
            section.contentInsets = NSDirectionalEdgeInsets(
                top: 0,
                leading: horizontal,
                bottom: 0,
                trailing: horizontal)

            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(100.0))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: size,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems = [header]
            return section
        }
        return layout
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        news.subscribeAndReceive(self) { [weak self] in
            self?.items = $0.map { .init(model: $0, promo: nil) }
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
        collection?.reloadData()
        collection?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_: UICollectionView, numberOfItemsInSection: Int) -> Int {
        items.count
    }
    
    func collectionView(_: UICollectionView, viewForSupplementaryElementOfKind kind: String, at: IndexPath) -> UICollectionReusableView {
        let header = collection.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: at)
        return header
    }
    
    func collectionView(_: UICollectionView, cellForItemAt: IndexPath) -> UICollectionViewCell {
        let cell = collection.dequeueReusableCell(withReuseIdentifier: identifier, for: cellForItemAt) as! NewsCell
        cell.configure(items[cellForItemAt.row], images: images, positions: .derive(row: cellForItemAt.item, items: items.count))
        return cell
    }


    func collectionView(_: UICollectionView, didSelectItemAt: IndexPath) {
        let item = items[didSelectItemAt.row]
        delegate?.yourImpact(didSelectURL: item.targetUrl)
        dismiss(animated: true, completion: nil)
        Analytics.shared.navigationOpenNews(item.trackingName)
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

private final class NewsSubHeader: UICollectionReusableView, NotificationThemeable {
    private weak var subtitle: UILabel!
    
    required init?(coder: NSCoder) { nil }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .preferredFont(forTextStyle: .body)
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.numberOfLines = 0
        subtitle.text = .localized(.keepUpToDate)
        addSubview(subtitle)
        self.subtitle = subtitle
        
        subtitle.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        subtitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16).isActive = true
        subtitle.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        subtitle.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
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
