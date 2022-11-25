/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core

protocol YourImpactDelegate: AnyObject {
    func yourImpact(didSelectURL url: URL)
}

final class YourImpact: UICollectionViewController, UICollectionViewDelegateFlowLayout, NotificationThemeable {
    var delegate: YourImpactDelegate?
    private weak var referrals: Referrals!
    private var disclosed: IndexPath?
    private let images = Images(.init(configuration: .ephemeral))
    private let personalCounter = PersonalCounter()
    private let background = Background()
    private weak var impactCell: MyImpactCell?

    convenience init(delegate: YourImpactDelegate?, referrals: Referrals) {
        let layout = YourImpactLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.footerReferenceSize = .zero
        layout.headerReferenceSize = .zero
        
        self.init(collectionViewLayout: layout)
        self.title = .localized(.yourImpact)
        self.delegate = delegate
        self.referrals = referrals
        navigationItem.largeTitleDisplayMode = .always
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let done = UIBarButtonItem(barButtonSystemItem: .done) { [ weak self ] _ in
            self?.dismiss(animated: true, completion: nil)
        }
        navigationItem.rightBarButtonItem = done

        Section.allCases.forEach {
            collectionView!.register($0.cell, forCellWithReuseIdentifier: String(describing: $0.cell))
        }
        collectionView!.register(ImpactHeaderCell.self, forCellWithReuseIdentifier: .init(describing: ImpactHeaderCell.self))
        collectionView.delegate = self
        collectionView.contentInsetAdjustmentBehavior = .scrollableAxes

        NotificationCenter.default.addObserver(self, selector: #selector(updateLayout), name: UIDevice.orientationDidChangeNotification, object: nil)

        applyTheme()

        personalCounter.subscribe(self)  { [weak self] _ in
            guard
                let self = self,
                self.collectionView.numberOfSections > Section.impact.rawValue
            else { return }
            self.collectionView.reloadSections([Section.impact.rawValue])
        }

        referrals.subscribe(self)  { [weak self] _ in
            guard
                let self = self,
                self.collectionView.numberOfSections > Section.impact.rawValue
            else { return }
            self.updateImpactCell()
        }
    }

    private var disappeared = Date.distantFuture
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Analytics.shared.navigation(.view, label: .home)

        referrals.refresh(force: true)

        User.shared.hideRebrandIntro()

        if #available(iOS 15, *) {
            guard
                let cooldown = Calendar.current.date(byAdding: .second, value: 2, to: disappeared),
                cooldown < .now
            else {
                disappeared = .distantFuture
                return
            }
        } else {
            guard
                let cooldown = Calendar.current.date(byAdding: .second, value: 2, to: disappeared),
                cooldown < .init()
            else {
                disappeared = .distantFuture
                return
            }
        }
        
        updateBarAppearance()
        collectionView.scrollRectToVisible(.init(x: 0, y: 0, width: 1, height: 1), animated: false)
        collectionView.reloadData()
        disappeared = .distantFuture
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if #available(iOS 15, *) {
            disappeared = .now
        } else {
            disappeared = .init()
        }
    }

    // MARK: UICollectionViewDataSource
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
        case .impact: return 1
        case .multiply: return 2  // with header
        case .explore: return Section.Explore.allCases.count + 1 // header
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .impact:
            let impactCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath) as! MyImpactCell
            impactCell.howItWorksButton.removeTarget(self, action: nil, for: .touchUpInside)
            impactCell.howItWorksButton.addTarget(self, action: #selector(learnMore(button:)), for: .touchUpInside)
            impactCell.howItWorksButton.addTarget(self, action: #selector(learnMoreHoverOn(button:)), for: .touchDown)
            impactCell.howItWorksButton.addTarget(self, action: #selector(learnMoreHoverOff(button:)), for: .touchUpOutside)
            impactCell.howItWorksButton.addTarget(self, action: #selector(learnMoreHoverOff(button:)), for: .touchCancel)
            self.impactCell = impactCell
            updateImpactCell()
            return impactCell

        case .multiply:
            if indexPath.row == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .init(describing: ImpactHeaderCell.self), for: indexPath) as! ImpactHeaderCell
                cell.title.text = section.title
                return cell
            } else {
                let multiplyCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath) as! MultiplyImpactCell
                return multiplyCell
            }
        case .explore:
            if indexPath.row == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: .init(describing: ImpactHeaderCell.self), for: indexPath) as! ImpactHeaderCell
                cell.title.text = section.title
                return cell
            } else {
                let exploreCell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: section.cell), for: indexPath) as! EcosiaExploreCell
                exploreCell.learnMore.tag = indexPath.row - 1
                exploreCell.learnMore.removeTarget(self, action: nil, for: .touchUpInside)
                exploreCell.learnMore.addTarget(self, action: #selector(explore(button:)), for: .touchUpInside)
                exploreCell.model = .init(rawValue: indexPath.row - 1)
                return exploreCell
            }
        }
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = Section(rawValue: indexPath.section)!
        switch section {
        case .explore:
            // Index is off by one as first cell is the header
            guard indexPath.row > 0 else { return }

            collectionView.performBatchUpdates({
                disclosed = disclosed == indexPath ? nil : indexPath
                UIView.animate(withDuration: 0.3) {
                    collectionView.collectionViewLayout.invalidateLayout()
                }
            }) { [weak collectionView] in
                collectionView?.scrollToItem(at: indexPath, at: .top, animated: $0)
                collectionView?.deselectItem(at: indexPath, animated: false)
            }
        case .multiply:
            navigationController?.pushViewController(MultiplyImpact(delegate: delegate, referrals: referrals), animated: true)
            collectionView.deselectItem(at: indexPath, animated: false)
        default:
            break
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let section = Section(rawValue: indexPath.section)!
        let height: CGFloat
        
        switch Section(rawValue: indexPath.section)! {
        case .explore:
            if indexPath == disclosed {
                if let cell = collectionView.cellForItem(at: indexPath) as? EcosiaExploreCell {
                    height = cell.expandedHeight
                } else {
                    disclosed = nil
                    height = section.height
                }
            } else {
                height = section.height
            }
        default:
            height = section.height
        }
        
        return .init(width: collectionView.yourImpactMaxWidth, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {

        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .multiply, .explore:
            return 0
        default:
            return 16
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout: UICollectionViewLayout, insetForSectionAt: Int) -> UIEdgeInsets {
        let vertical = insetForSectionAt == Section.explore.rawValue ? 26 : CGFloat()
        let horizontal = (collectionView.bounds.width - collectionView.yourImpactMaxWidth) / 2
        return .init(top: 0, left: horizontal, bottom: vertical, right: horizontal)
    }
    
    func applyTheme() {
        collectionView.reloadData()
        view.backgroundColor = UIColor.theme.ecosia.modalBackground
        collectionView.backgroundColor = .clear
        background.backgroundColor = .theme.ecosia.modalHeader
        updateBarAppearance()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        background.inset = max(background.inset, scrollView.adjustedContentInset.top)
        background.offset = scrollView.contentOffset.y
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        updateLayout()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateLayout()
        applyTheme()
    }
    
    private func updateBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .theme.ecosia.modalHeader
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.Dark.Text.primary]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.Dark.Text.primary]
        appearance.shadowColor = UIColor.theme.ecosia.impactSeparator
        appearance.shadowImage = UIImage()
        navigationItem.standardAppearance = appearance

        navigationController?.navigationBar.backgroundColor = .theme.ecosia.modalHeader
        navigationController?.navigationBar.tintColor = .Dark.Text.primary
        collectionView.backgroundView = background
        navigationController?.navigationBar.setNeedsDisplay()
    }
    
    @objc private func updateLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func updateImpactCell() {
        guard let impactCell = impactCell else {
            return
        }
        impactCell.update(personalCounter: personalCounter.state ?? 0, progress: User.shared.progress)
    }

    @objc private func inviteFriends() {
        navigationController?.pushViewController(MultiplyImpact(delegate: delegate, referrals: referrals), animated: true)
    }

    @objc private func learnMore(button: UIControl) {
        delegate?.yourImpact(didSelectURL: Environment.current.aboutCounter)
        Analytics.shared.navigation(.open, label: .counter)
        
        dismiss(animated: true) { [weak self] in
            self?.learnMoreHoverOff(button: button)
        }
    }
    
    @objc private func learnMoreHoverOn(button: UIControl) {
        button.alpha = 0.5
    }
    
    @objc private func learnMoreHoverOff(button: UIControl) {
        button.alpha = 1
    }
    
    @objc private func explore(button: UIButton) {
        Section.Explore(rawValue: button.tag)
            .map {
                delegate?.yourImpact(didSelectURL: $0.url)
                Analytics.shared.navigation(.open, label: $0.label)
            }
        dismiss(animated: true, completion: nil)
    }
}
