/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

protocol EcosiaHomeDelegate: AnyObject {
    func ecosiaHome(didSelectURL url: URL)
}

final class EcosiaHome: UICollectionViewController, UICollectionViewDelegateFlowLayout, Themeable {

    enum Section: Int, CaseIterable {
        case logo, info, news, explore

        var cell: AnyClass {
            switch self {
            case .logo: return TreeCounterCell.self
            case .info: return EcosiaInfoCell.self
            case .explore: return EcosiaExploreCell.self
            case .news: return NewsCell.self
            }
        }

        var sectionTitle: String? {
            if self == .explore { return .localized(.exploreEcosia) }
            if self == .news { return .localized(.stories) }
            return nil
        }

        enum Info: Int, CaseIterable {
            case treeCount

            var title: String {
                switch self {
                case .treeCount:
                    return .localized(.mySearches)
                }
            }

            var subTitle: String? {
                if self == .treeCount {
                    return "\(User.shared.treeCount)"
                }
                return nil
            }

            var description: String? {
                switch self {
                case .treeCount:
                    return .localized(.youNeedAround45)
                }
            }

            var image: String {
                switch self {
                case .treeCount:
                    return "treeCounter"
                }
            }
        }

        enum Explore: Int, CaseIterable {
            case info, finance, trees, faq, shop

            var title: String {
                switch self {
                case .info:
                    return .localized(.howEcosiaWorks)
                case .finance:
                    return .localized(.financialReports)
                case .trees:
                    return .localized(.trees)
                case .faq:
                    return .localized(.faq)
                case .shop:
                    return .localized(.shop)
                }
            }

            var image: String {
                switch self {
                case .info:
                    return "networkTree"
                case .finance:
                    return "reports"
                case .trees:
                    return "treesIcon"
                case .faq:
                    return "faqIcon"
                case .shop:
                    return "shopIcon"
                }
            }

            var url: URL {
                switch self {
                case .info:
                    return Environment.current.howEcosiaWorks
                case .finance:
                    return Environment.current.financialReports
                case .trees:
                    return Environment.current.trees
                case .faq:
                    return Environment.current.faq
                case .shop:
                    return Environment.current.shop
                }
            }
        }
    }

    var delegate: EcosiaHomeDelegate?
    private var items = [NotificationModel]()
    private let images = Images(.init(configuration: .ephemeral))
    private let notifications = Notifications(.main)

    convenience init(delegate: EcosiaHomeDelegate?) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        self.init(collectionViewLayout: layout)

        self.delegate = delegate
        navigationItem.largeTitleDisplayMode = .never
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let done = UIBarButtonItem(barButtonSystemItem: .done) { [ weak self ] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        navigationItem.leftBarButtonItem = done

        Section.allCases.forEach {
            collectionView!.register($0.cell, forCellWithReuseIdentifier: String(describing: $0.cell))
        }
        collectionView.register(ASHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        collectionView.register(NewsButtonCell.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer")
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .always
        applyTheme()

        notifications.subscribe(self) { [weak self] in
            self?.items = $0
            self?.collectionView.reloadSections([Section.news.rawValue, Section.info.rawValue])
        }
        
        Goodall.shared.loading.notify(queue: .main) { [weak self] in
            self?.notifications.load(session: .shared)
        }
    }

    private var hasAppeared: Bool = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard hasAppeared else { return hasAppeared = true }
        collectionView.reloadSections([Section.info.rawValue])
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return Section.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .logo: return 1
        case .info: return Section.Info.allCases.count
        case .explore: return Section.Explore.allCases.count
        case .news: return min(3, items.count)
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let section = Section(rawValue: indexPath.section)!
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath)

        switch  section {
        case .logo:
            break
        case .info:
            let infoCell = cell as! EcosiaInfoCell
            Section.Info(rawValue: indexPath.row).map { infoCell.display($0) }
        case .explore:
            let exploreCell = cell as! EcosiaExploreCell
            Section.Explore(rawValue: indexPath.row).map { exploreCell.display($0) }
        case .news:
            let cell = cell as! NewsCell
            cell.configure(items[indexPath.row], images: images)
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        guard let section = Section(rawValue: indexPath.section) else { return  UICollectionReusableView() }

        switch kind {
        case UICollectionView.elementKindSectionHeader:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header", for: indexPath) as! ASHeaderView
            view.title = section.sectionTitle
            return view
        case UICollectionView.elementKindSectionFooter:
            let view = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "Footer", for: indexPath) as! NewsButtonCell
            view.moreButton.setTitle(.localized(.more), for: .normal)
            view.moreButton.addTarget(self, action: #selector(allNews), for: .touchUpInside)
            return view
        default:
            return UICollectionReusableView()
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .info:
            if indexPath.row == 0 {
                delegate?.ecosiaHome(didSelectURL: Environment.current.aboutCounter)
                dismiss(animated: true, completion: nil)
            }
        case .news:
            delegate?.ecosiaHome(didSelectURL: items[indexPath.row].targetUrl)
            dismiss(animated: true, completion: nil)
        case .explore:
            Section.Explore(rawValue: indexPath.row)
                .map { delegate?.ecosiaHome(didSelectURL: $0.url) }
            dismiss(animated: true, completion: nil)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = Section(rawValue: indexPath.section)!

        let margin = max(16, collectionView.adjustedContentInset.left)

        switch section {
        case .logo:
            return CGSize(width: view.bounds.width - 2 * margin, height: 150)
        case .info:
            return CGSize(width: view.bounds.width - 2 * margin, height: 140)
        case .news:
            return CGSize(width: view.bounds.width - 2 * margin, height: 130)
        case .explore:

            var width = (view.bounds.width - 2 * margin - 16)/2.0
            width = min(width, 180)
            return CGSize(width: width, height: width + 32)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        switch Section(rawValue: section)! {
        case .logo:
            return .zero
        case .explore, .news:
            return CGSize(width: view.bounds.width - 32, height: 60)
        case .info:
            return CGSize(width: view.bounds.width - 32, height: 24)

        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {

        switch Section(rawValue: section)! {
        case .news:
            return CGSize(width: view.bounds.width - 32, height: 36)
        default:
            return .zero
        }

    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .news:
            return 0
        default:
            return 16
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 0, left: 16, bottom: 0, right: 16)
    }

    @objc private func allNews() {
        let news = NewsController(items: items, delegate: delegate)
        navigationController?.pushViewController(news, animated: true)
    }

    func applyTheme() {
        collectionView.reloadData()
        view.backgroundColor = UIColor.theme.ecosia.primaryBackground
        collectionView.backgroundColor = UIColor.theme.ecosia.primaryBackground
        navigationItem.leftBarButtonItem?.tintColor = UIColor.theme.ecosia.primaryToolbar
    }
}
