// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

protocol TabTrayAnimationQueue {
    func addAnimation(for collectionView: UICollectionView,
                      animation: @escaping (() -> Void))
}

class TabTrayAnimationQueueImplementation: TabTrayAnimationQueue {
    private var animations = [() -> Void]()
    private var performingChainedOperations = false

    func addAnimation(for collectionView: UICollectionView,
                      animation: @escaping (() -> Void)) {
        animations.append(animation)
        performChainedOperations(for: collectionView)
    }

    private func performChainedOperations(for collectionView: UICollectionView) {
        guard !performingChainedOperations,
              let animation = animations.first
        else { return }

        performingChainedOperations = true
        animations.removeFirst()
        /// Fix crash related to bug from `collectionView.performBatchUpdates` when the
        /// collectionView is not visible the dataSource section/items differs from the actions to be perform
        /// which causes the crash
        if collectionView.numberOfSections != 0 {
            collectionView.numberOfItems(inSection: 0)
        }
        collectionView.performBatchUpdates({
            animation()
        }, completion: { [weak self] (done) in
            collectionView.reloadData()
            self?.performingChainedOperations = false
            self?.performChainedOperations(for: collectionView)
        })
    }
}
