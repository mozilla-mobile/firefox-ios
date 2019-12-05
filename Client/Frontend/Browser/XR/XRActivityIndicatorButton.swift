import Foundation
import UIKit

class ActivityIndicatorButton: UIButton {
    
    @IBInspectable var indicatorColor : UIColor = .gray
    
    var buttonImage: UIImage?
    
    func startAnimating() {
        self.isEnabled = false
        
        buttonImage = self.imageView?.image
        self.setImage(nil, for: .normal)
        
        let indicator = UIActivityIndicatorView()
        indicator.color = indicatorColor
        indicator.hidesWhenStopped = true
        indicator.tag = 99
        
        let buttonHeight = self.bounds.size.height
        let buttonWidth = self.bounds.size.width
        indicator.center = CGPoint(x: buttonWidth/2, y: buttonHeight/2)
        
        let scale = max(min((self.frame.size.height - 4) / 21, 2.0), 0.0)
        let transform: CGAffineTransform = CGAffineTransform(scaleX: scale, y: scale)
        indicator.transform = transform
        
        self.addSubview(indicator)
        indicator.startAnimating()
    }
    
    func stopAnimating() {
        
        if let image = buttonImage {
            self.setImage(image, for: .normal)
        }
        
        if let indicator = self.viewWithTag(99) as? UIActivityIndicatorView {
            indicator.stopAnimating()
            indicator.removeFromSuperview()
        }
    }
}
