import UIKit

public class SiteImageView: UIImageView {
    private var uniqueID: UUID?

    public func setURL(siteURL: String, type: SiteImageType = .favicon) {
        uniqueID = UUID()
        backgroundColor = .magenta
    }
}
