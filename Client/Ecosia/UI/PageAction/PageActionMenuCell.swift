// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

final class PageActionMenuCell: UITableViewCell {
    
    struct UX {
        
        static let cellIdentifier = String(describing: PageActionMenuCell.self)
        
        /// The corner radius to apply to the cells
        /// depending on their position
        static let cornerRadius: CGFloat = 10.0
        
        /// The cell's left / right padding
        static let padding: CGFloat = 16.0
        
        /// The separator height of the `PageActionMenuCell`'s `separatorView`
        static let separatorHeight: CGFloat = 1.0
        
        /// This `enum` serves the purpose of checking the cells' position
        /// within a section
        enum Position {
            /// Only one cell is rendered within a section
            case solo
            /// The cell is the first of its section
            case first
            /// The cell is between the first and last of its section
            case middle
            /// The cell is the last of its section
            case last
        }
    }
    
    private weak var badge: UIView?
    private weak var badgeLabel: UILabel?
    private var separatorView: UIView?
    
    /// The cell's position, starting from `middle` as preferred value
    private var position: UX.Position = .middle
    
    /// The eligible cell positions within the Table View
    /// to add the separator view
    private let separatorCellsPositions: [UX.Position] = [.middle, .first]
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        adjustPadding()
        setTableViewCellCorners()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        separatorView?.removeFromSuperview()
        separatorView = nil
        textLabel?.text = nil
        imageView?.image = nil
    }
}

extension PageActionMenuCell {
    
    /// Determines the TableView Cell's position based at a given Index Path
    ///
    /// - Parameters:
    ///    - indexPath: The Table View's index path
    ///    - actions: The array of `PhotonRowActions` utilized as Data Source
    @discardableResult
    func determineTableViewCellPositionAt(_ indexPath: IndexPath, forActions actions: [[PhotonRowActions]]) -> UX.Position {
        
        if actions[indexPath.section].count == 1 {
            position = .solo
        } else if indexPath.row == 0 {
            position = .first
        } else if (indexPath.row == actions[indexPath.section].count - 1) {
            position = .last
        } else {
            position = .middle
        }
        
        return position
    }
    
}

extension PageActionMenuCell {
    
    /// Sets the left/right padding of the Table View Cell's content view
    private func adjustPadding() {
        
        guard let superview else { return }
        
        let frameWithPadding = CGRect(x: UX.padding,
                                      y: frame.minY,
                                      width: superview.frame.width - (UX.padding * 2),
                                      height: frame.height)
        frame = frameWithPadding
        let insets = NSDirectionalEdgeInsets(top: 0,
                                             leading: UX.padding,
                                             bottom: 0,
                                             trailing: UX.padding)
        contentView.directionalLayoutMargins = insets
    }
    
    /// Sets the table view cell's corners based on the `position`
    private func setTableViewCellCorners() {
        switch position {
        case .solo: addRoundedCorners(.allCorners, radius: UX.cornerRadius)
        case .first: addRoundedCorners([.topLeft, .topRight], radius: UX.cornerRadius)
        case .last: addRoundedCorners([.bottomLeft, .bottomRight], radius: UX.cornerRadius)
        default: noCornerMask()
        }
    }
}

extension PageActionMenuCell {
    
    /// Reset the Corner Mask of a given `UIView` (`PageActionMenuCell`)
    ///
    /// Perhaps moved into a different `UIView` extension
    /// Although we use this function purely to solve this Table View Cell's UI behaviour
    private func noCornerMask() {
        layer.mask = nil
    }
    
    /// Adds the custom separator view
    private func addCustomGroupedStyleLikeSeparator() {
        
        if separatorView == nil {
            separatorView = UIView()
        }
                
        guard let separatorView else { return }
        
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = .legacyTheme.ecosia.border
        
        contentView.addSubview(separatorView)
        contentView.bringSubviewToFront(separatorView)
        
        updateSeparatorViewConstraints(separatorView)
    }
        
    private func updateSeparatorViewConstraints(_ separatorView: UIView) {
        separatorView.heightAnchor.constraint(equalToConstant: UX.separatorHeight).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.separatorHeight).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.padding).isActive = true
        if let imageView {
            separatorView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor).isActive = true
        } else if let textLabel {
            separatorView.leadingAnchor.constraint(equalTo: textLabel.leadingAnchor).isActive = true
        }
    }
}

extension PageActionMenuCell {
    
    /// Configures the TableView's cell
    ///
    /// - Parameters:
    ///   - viewModel: The`PhotonActionSheetViewModel`'s View Model
    ///   - indexPath: The TableView's index path
    func configure(with viewModel: PhotonActionSheetViewModel, at indexPath: IndexPath) {
        
        backgroundColor = .legacyTheme.ecosia.impactMultiplyCardBackground
        let actions = viewModel.actions[indexPath.section][indexPath.row]
        guard let item = actions.items.first else { return }
        
        textLabel?.text = item.currentTitle
        textLabel?.textColor = .legacyTheme.ecosia.primaryText
        detailTextLabel?.text = item.text
        detailTextLabel?.textColor = .legacyTheme.ecosia.secondaryText
        
        accessibilityIdentifier = item.iconString ?? item.accessibilityId
        accessibilityLabel = item.currentTitle
        
        if let iconName = item.iconString {
            imageView?.image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate)
            imageView?.tintColor = .legacyTheme.ecosia.secondaryText
        } else {
            imageView?.image = nil
        }
        
        isNew(actions.items.first?.isNew == true)

        if separatorCellsPositions.contains(position) {
            addCustomGroupedStyleLikeSeparator()
        }
    }
}

extension PageActionMenuCell {
    
    /// Creates the TableView Cell's `badge` based on a condition
    ///
    /// - Parameters:
    ///    - isNew: A boolean value based on which we create the `badge` view
    private func isNew(_ isNew: Bool) {
        if isNew {
            if badge == nil {
                let badge = UIView()
                badge.isUserInteractionEnabled = false
                accessoryView = badge
                
                let badgeLabel = UILabel()
                badgeLabel.translatesAutoresizingMaskIntoConstraints = false
                badgeLabel.font = .preferredFont(forTextStyle: .footnote).bold()
                badgeLabel.adjustsFontForContentSizeCategory = true
                badgeLabel.text = .localized(.new)
                badge.addSubview(badgeLabel)
                
                badgeLabel.centerXAnchor.constraint(equalTo: badge.centerXAnchor).isActive = true
                badgeLabel.centerYAnchor.constraint(equalTo: badge.centerYAnchor).isActive = true
                
                self.badge = badge
                self.badgeLabel = badgeLabel
            }
            
            let size = badgeLabel?.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude)) ?? .zero
            let height = size.height + 5
            badge?.layer.cornerRadius = height / 2
            badge?.frame.size = .init(width: size.width + 16, height: height)
            badge?.backgroundColor = .legacyTheme.ecosia.primaryBrand
            badgeLabel?.textColor = .legacyTheme.ecosia.primaryTextInverted
        } else {
            accessoryView = nil
        }
    }
}
