import UIKit

class TipsPageViewController: UIViewController {
    enum State {
        case showTips
        case showEmpty(controller: UIViewController)
    }
    
    private var emptyController: UIViewController?
    
    private var tipManager: TipManager
    private let tipTapped: (TipManager.Tip) -> ()
    
    private lazy var pageController: UIPageViewController = {
        let pageController = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        pageController.dataSource = self
        pageController.delegate = self
        pageController.view.backgroundColor = .clear
        return pageController
    }()
    
    init(tipManager: TipManager, tipTapped: @escaping (TipManager.Tip) -> ()) {
        self.tipManager = tipManager
        self.tipTapped = tipTapped
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
    
    func setupPageController(with state: State) {
        pageController.removeAsChild()
        emptyController?.removeAsChild()
        
        switch state {
        case .showTips:
            guard let initialVC = tipManager.fetchTip().map({ TipViewController(tip: $0, tipTapped: tipTapped) }) else { return }
            install(pageController, on: self.view)
            self.pageController.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
            
        case .showEmpty(let controller):
            emptyController = controller
            install(controller, on: self.view)
        }
        
    }
}

extension TipsPageViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let tip = (viewController as! TipViewController).tip
        return tipManager.getTip(before: tip).map { TipViewController(tip: $0, tipTapped: tipTapped) }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let tip = (viewController as! TipViewController).tip
        return tipManager.getTip(after: tip).map { TipViewController(tip: $0, tipTapped: tipTapped) }
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.tipManager.numberOfTips()
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0
    }
}
