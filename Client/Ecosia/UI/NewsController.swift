/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Core
import UIKit

final class NewsController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout, Themeable {
    private weak var collection: UICollectionView!
    private var items = [NotificationModel]()
    private let images = Images(.init(configuration: .ephemeral))
    private let notifications = Notifications(.main)
    private let identifier = "news"
    var delegate: EcosiaHomeDelegate?

    required init?(coder: NSCoder) { nil }

    init(items: [NotificationModel], delegate: EcosiaHomeDelegate?) {
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
        flow.sectionInset = .init(top: 0, left: 16, bottom: 0, right: 16)
        flow.headerReferenceSize.height = 100

        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.startAnimating()
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flow)
        collection.delegate = self
        collection.dataSource = self
        collection.register(NewsCell.self, forCellWithReuseIdentifier: identifier)
        collection.register(NewsHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: identifier)
        collection.backgroundView = indicator
        collection.contentInsetAdjustmentBehavior = .always
        self.collection = collection
        view = collection
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        notifications.subscribe(self) { [weak self] in
            self?.items = $0
            self?.collection.reloadData()
        }

        if items.isEmpty {
            notifications.load(session: .shared)
        }

        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //TODO: Analytics.shared.screen(.news)
    }
    
    override func viewWillTransition(to: CGSize, with: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: to, with: with)
        collection?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_: UICollectionView, numberOfItemsInSection: Int) -> Int {
        items.count
    }
    
    func collectionView(_: UICollectionView, viewForSupplementaryElementOfKind kind: String, at: IndexPath) -> UICollectionReusableView {
        collection.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: at)
    }
    
    func collectionView(_: UICollectionView, cellForItemAt: IndexPath) -> UICollectionViewCell {
        let cell = collection.dequeueReusableCell(withReuseIdentifier: identifier, for: cellForItemAt) as! NewsCell
        cell.configure(items[cellForItemAt.row], images: images)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAt: IndexPath) -> CGSize {
        let margin = max(32, (collectionView.adjustedContentInset.left + collection.adjustedContentInset.right))
        return .init(width: collection.bounds.width - margin, height: 131)
    }
    
    func collectionView(_: UICollectionView, didSelectItemAt: IndexPath) {
        let item = items[didSelectItemAt.row]
        delegate?.ecosiaHome(didSelectURL: item.targetUrl)
        dismiss(animated: true, completion: nil)
        // TODO: Analytics.shared.news(item.trackingName)
    }

    func applyTheme() {
        collection.reloadData()
        collection.backgroundColor = UIColor.theme.ecosia.primaryBackground
    }
}

private final class NewsHeader: UICollectionReusableView, Themeable {
    private weak var subtitle: UILabel!
    required init?(coder: NSCoder) { nil }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        isUserInteractionEnabled = false

        let subtitle = UILabel()
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.font = .preferredFont(forTextStyle: .title3)
        subtitle.numberOfLines = 0
        subtitle.text = .localized(.keepUpToDate)
        addSubview(subtitle)
        self.subtitle = subtitle
        
        subtitle.topAnchor.constraint(equalTo: topAnchor, constant: 16).isActive = true
        subtitle.leftAnchor.constraint(equalTo: safeAreaLayoutGuide.leftAnchor, constant: 16).isActive = true
        subtitle.rightAnchor.constraint(equalTo: safeAreaLayoutGuide.rightAnchor, constant: -16).isActive = true
        subtitle.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true

        applyTheme()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }

    func applyTheme() {
        backgroundColor = UIColor.theme.ecosia.primaryBackground
        subtitle.textColor = UIColor.theme.ecosia.secondaryText
    }
}
