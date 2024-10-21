// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A protocol for any object to inherit the `cellIdentifier` string property.
///
/// Intended for use with views that must register/deque cells, this allows
/// a cleaner implementation of the cell identifier by bypassing it being
/// hardcoded which is prone to error.
///
/// As defined in the extensions, this will generally, where adhering to the
/// implemented conditions, return a string describing `self`.
public protocol ReusableCell: AnyObject {
    static var cellIdentifier: String { get }
}

public extension ReusableCell where Self: UICollectionViewCell {
    static var cellIdentifier: String { return String(describing: self) }
}

public extension ReusableCell where Self: UITableViewCell {
    static var cellIdentifier: String { return String(describing: self) }
}

public extension ReusableCell where Self: UITableViewHeaderFooterView {
    static var cellIdentifier: String { return String(describing: self) }
}

public extension ReusableCell where Self: UICollectionReusableView {
    static var cellIdentifier: String { return String(describing: self) }
}

public extension UICollectionView {
    func dequeueReusableCell<T: ReusableCell>(cellType: T.Type, for indexPath: IndexPath) -> T? {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.cellIdentifier, for: indexPath) as? T
        else { return nil }

        return cell
    }

    func dequeueSupplementary<T: ReusableCell>(of kind: String, cellType: T.Type, for indexPath: IndexPath) -> T? {
        guard let cell = dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: T.cellIdentifier,
            for: indexPath) as? T
        else { return nil }

        return cell
    }

    func registerSupplementary<T: ReusableCell>(of kind: String, cellType: T.Type) {
        register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.cellIdentifier)
    }

    func register<T: ReusableCell>(cellType: T.Type) {
        register(T.self, forCellWithReuseIdentifier: T.cellIdentifier)
    }

    /// Returns `true` if the `indexPath` is not out of bounds.
    func isValid(indexPath: IndexPath) -> Bool {
        return 0..<numberOfSections ~= indexPath.section
               && 0..<numberOfItems(inSection: indexPath.section) ~= indexPath.row
    }

    /// Returns the list of UICollectionViewCells which are fully visible within the UICollectionView's bounds.
    /// Note: This list will be empty if there are pending layout updates.
    var fullyVisibleCells: [UICollectionViewCell] {
        return visibleCells.filter({ self.bounds.contains($0.frame) })
    }

    /// Returns the list of cell IndexPaths which are fully visible within the UICollectionView's bounds.
    /// Note: This list will be empty if there are pending layout updates.
    var indexPathsForFullyVisibleItems: [IndexPath] {
        return fullyVisibleCells.compactMap({ indexPath(for: $0) })
    }
}

public extension UITableView {
    func register<T: ReusableCell>(cellType: T.Type) {
        register(T.self, forCellReuseIdentifier: T.cellIdentifier)
    }

    func registerHeaderFooter<T: ReusableCell>(cellType: T.Type) {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.cellIdentifier)
    }
}
