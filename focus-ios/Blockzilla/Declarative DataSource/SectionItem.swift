import UIKit

struct SectionItem {
    let configureCell: (UITableView, IndexPath) -> UITableViewCell
    let action: (() -> Void)?
    
    init(configureCell: @escaping (UITableView, IndexPath) -> UITableViewCell, action: (() -> Void)? = nil) {
        self.configureCell = configureCell
        self.action = action
    }
}
