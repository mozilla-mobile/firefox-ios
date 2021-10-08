import UIKit

extension UITableView {
    open func dequeueReusableCell<Cell: UITableViewCell>(_ type: Cell.Type, withIdentifier identifier: String) -> Cell? {
        return self.dequeueReusableCell(withIdentifier: identifier) as? Cell
    }
    
    open func dequeueReusableCell<Cell: UITableViewCell>(_ type: Cell.Type, for indexPath: IndexPath) -> Cell? {
        return self.dequeueReusableCell(withIdentifier: String(describing: type), for: indexPath) as? Cell
    }
    
    func registerNib<Cell: UITableViewCell>(_ type: Cell.Type) {
        let nib = UINib(nibName: String(describing: type), bundle: nil)
        register(nib, forCellReuseIdentifier: String(describing: type))
    }
    func register<Cell: UITableViewCell>(_ type: Cell.Type) {
        register(type, forCellReuseIdentifier: String(describing: type))
    }
}
