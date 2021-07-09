/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class TipsPageControl: UIView {

    var currentPage: Int = 0 {
        didSet {
            changeDotsColor()
        }
    }
    
    var numberOfPages: Int = 0 {
        didSet {
            addDots()
        }
    }
    
    private let dotImage = #imageLiteral(resourceName: "page_indicator")
    private let stackView = UIStackView()
    private var dotsArray = [UIImageView]()

    init() {
        super.init(frame: CGRect.zero)
        
        stackView.spacing = UIConstants.layout.pageControlSpacing
        stackView.distribution = .equalCentering
        stackView.alignment = .center
        
        addDots()
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addDots() {
        for i in 0..<numberOfPages {
            let dot = UIImageView(image: dotImage)
            dot.image = imageFor(i)
            stackView.addArrangedSubview(dot)
            dotsArray.append(dot)
        }
    }
    
    private func changeDotsColor() {
        for i in 0..<numberOfPages {
            dotsArray[i].image = imageFor(i)
        }
    }
    
    private func imageFor(_ index: Int) -> UIImage {
        return index == currentPage ? dotImage : dotImage.alpha(0.4)
    }
}
