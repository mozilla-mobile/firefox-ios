
import UIKit

class ClipboardBar: UIView {
    
    let titleLabel = UILabel()
    let urlLabel = UILabel()
    let goButton = UIButton()
    let containerView = UIView()
    var urlString: String? {
        didSet {
            urlLabel.text = urlString
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        backgroundColor = UIColor(red: 98 / 255, green: 169 / 255, blue: 255 / 255, alpha: 1)
        
        containerView.backgroundColor = UIColor.clearColor()
        addSubview(containerView)
        
        titleLabel.text = NSLocalizedString("Go to copied link?", comment: "Clipboard bar title")
        titleLabel.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.DefaultMediumFontSize, weight: UIFontWeightRegular)
        urlLabel.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.DefaultMediumFontSize, weight: UIFontWeightRegular)

        titleLabel.textColor = UIColor.whiteColor()
        urlLabel.textColor = UIColor.whiteColor()
        
        goButton.setTitle(NSLocalizedString("Go", comment: "Clipboard bar button title"), forState: .Normal)
        goButton.layer.cornerRadius = 3
        goButton.layer.borderWidth = 1
        goButton.layer.borderColor = UIColor.whiteColor().CGColor
        goButton.titleLabel?.font = UIFont.systemFontOfSize(DynamicFontHelper.defaultHelper.DefaultMediumFontSize, weight: UIFontWeightRegular)
        goButton.addTarget(self, action: #selector(self.goButtonPressed), forControlEvents: .TouchUpInside)
        goButton.setTitleColor(UIColor.darkTextColor(), forState: .Highlighted)
        
        containerView.addSubview(goButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(urlLabel)
        
        setupLayout()
    }
    
    func goButtonPressed() {
        print("Go")
    }
    
    func setupLayout() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        goButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let margin: CGFloat = 10.0
        let buttonWidth: CGFloat = 80.0

        containerView.bottomAnchor.constraintEqualToAnchor(bottomAnchor, constant: -margin).active = true
        containerView.topAnchor.constraintEqualToAnchor(topAnchor, constant: margin).active = true
        containerView.leadingAnchor.constraintEqualToAnchor(leadingAnchor, constant: margin).active = true
        containerView.trailingAnchor.constraintEqualToAnchor(trailingAnchor, constant: -margin).active = true
        
        goButton.bottomAnchor.constraintEqualToAnchor(containerView.bottomAnchor).active = true
        goButton.topAnchor.constraintEqualToAnchor(containerView.topAnchor).active = true
        goButton.trailingAnchor.constraintEqualToAnchor(containerView.trailingAnchor).active = true
        goButton.widthAnchor.constraintEqualToConstant(buttonWidth).active = true
        
        titleLabel.topAnchor.constraintEqualToAnchor(containerView.topAnchor).active = true
        titleLabel.trailingAnchor.constraintEqualToAnchor(goButton.leadingAnchor, constant: -margin).active = true
        titleLabel.leadingAnchor.constraintEqualToAnchor(containerView.leadingAnchor).active = true

        urlLabel.bottomAnchor.constraintEqualToAnchor(containerView.bottomAnchor).active = true
        urlLabel.trailingAnchor.constraintEqualToAnchor(goButton.leadingAnchor, constant: -margin).active = true
        urlLabel.leadingAnchor.constraintEqualToAnchor(containerView.leadingAnchor).active = true
        
        
        
    }
}
