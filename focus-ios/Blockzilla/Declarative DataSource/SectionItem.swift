import UIKit

struct SectionItem {

    let id = UUID()

    let configureCell: (UITableView, IndexPath) -> UITableViewCell
    let action: (() -> Void)?

    init(configureCell: @escaping (UITableView, IndexPath) -> UITableViewCell, action: (() -> Void)? = nil) {
        self.configureCell = configureCell
        self.action = action
    }
}

extension SectionItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.id == rhs.id
    }
}
