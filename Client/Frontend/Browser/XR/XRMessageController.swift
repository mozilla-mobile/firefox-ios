import UIKit
import XCGLogger
import Shared

enum ResetTrackingOption {
    case resetTracking
    case removeExistingAnchors
    case saveWorldMap
    case loadSavedWorldMap
}

class MessageController: NSObject, UITableViewDelegate, UITableViewDataSource {
    
    var didShowMessage: (() -> Void)?
    var didHideMessage: (() -> Void)?
    var didHideMessageByUser: (() -> Void)?
    private weak var viewController: UIViewController?
    private weak var arPopup: UIAlertController?
    var requestXRPermissionsVC: RequestXRPermissionsViewController?
    private var webXRAuthorizationRequested: WebXRAuthorizationState = .notDetermined
    private var site: String?
    var permissionsPopup: UIViewController?
    var forceShowPermissionsPopup = false
    private let log = Logger.browserLogger

    init(viewController vc: UIViewController?) {
        super.init()
        
        viewController = vc
    }
    
    deinit {
        log.debug("MessageController dealloc")
    }
    
    func clean() {
        if arPopup != nil {
            arPopup?.dismiss(animated: false)
            arPopup = nil
        }
        
        if viewController?.presentedViewController != nil {
            viewController?.presentedViewController?.dismiss(animated: false)
        }
    }
    
    func arMessageShowing() -> Bool {
        return arPopup != nil
    }
    
    func hideMessages() {
        viewController?.presentedViewController?.dismiss(animated: true)
    }

    func showMessageAboutWebError(_ error: Error?, withCompletion reloadCompletion: @escaping (_ reload: Bool) -> Void) {
        weak var blockSelf: MessageController? = self
        let popup = UIAlertController(title: "Cannot Open the Page",
                                      message: "Please check the URL and try again",
                                      preferredStyle: .alert)

        let cancel = UIAlertAction(title: "Ok", style: .cancel) { action in
            reloadCompletion(false)
            blockSelf?.didHideMessageByUser?()
        }
        popup.addAction(cancel)
        
        let ok = UIAlertAction(title: "Reload", style: .default) { action in
            reloadCompletion(true)
            blockSelf?.didHideMessageByUser?()
        }
        popup.addAction(ok)
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    func showMessageAboutARInterruption(_ interrupt: Bool) {
        if interrupt && arPopup == nil {
            let popup = UIAlertController(title: "AR Interruption Occurred",
                                          message: "Please wait, it should be fixed automatically",
                                          preferredStyle: .alert)

            arPopup = popup
            viewController?.present(popup, animated: true)
            didShowMessage?()
        } else if !interrupt && arPopup != nil {
            arPopup?.dismiss(animated: true)
            arPopup = nil
            didHideMessage?()
        }
    }

    func showMessageAboutFailSession(withMessage message: String?, completion: @escaping () -> Void) {
        weak var blockSelf: MessageController? = self
        let popup = UIAlertController(title: "AR Session Failed",
                                      message: message,
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .default) { action in
            popup.dismiss(animated: true, completion: nil)
            blockSelf?.didHideMessageByUser?()
            completion()
        }
        popup.addAction(ok)
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    func showMessage(withTitle title: String?, message: String?, hideAfter seconds: Int) {
        let popup = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        viewController?.present(popup, animated: true)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(seconds), execute: {
            popup.dismiss(animated: true)
        })
    }

    func showMessageAboutMemoryWarning(withCompletion completion: @escaping () -> Void) {
        weak var blockSelf: MessageController? = self
        let popup = UIAlertController(title: "Memory Issue Occurred",
                                      message: "There was not enough memory for the application to keep working",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .default) { action in
            popup.dismiss(animated: true, completion: nil)
            completion()
            blockSelf?.didHideMessageByUser?()
        }

        popup.addAction(ok)
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    func showMessageAboutConnectionRequired() {
        weak var blockSelf: MessageController? = self
        let popup = UIAlertController(title: "Internet Connection is Unavailable",
                                      message: "Application will restart automatically when a connection becomes available",
                                      preferredStyle: .alert)

        let ok = UIAlertAction(title: "Ok", style: .default) { action in
            popup.dismiss(animated: true, completion: nil)
            blockSelf?.didHideMessageByUser?()
        }

        popup.addAction(ok)
        viewController?.present(popup, animated: true)
        didShowMessage?()
    }

    func showMessageAboutResetTracking(_ responseBlock: @escaping (ResetTrackingOption) -> Void) {
        let popup = UIAlertController(title: "Reset Tracking",
                                      message: "Please select one of the options below",
                                      preferredStyle: .actionSheet)
        
        let resetTracking = UIAlertAction(title: "Completely restart tracking", style: .default) { action in
            responseBlock(.resetTracking)
        }
        popup.addAction(resetTracking)
        
        let removeExistingAnchors = UIAlertAction(title: "Remove known anchors", style: .default) { action in
            responseBlock(.removeExistingAnchors)
        }
        popup.addAction(removeExistingAnchors)
        
        let saveWorldMap = UIAlertAction(title: "Save World Map", style: .default) { action in
            responseBlock(.saveWorldMap)
        }
        popup.addAction(saveWorldMap)
        
        let loadWorldMap = UIAlertAction(title: "Load previously saved World Map", style: .default) { action in
            responseBlock(.loadSavedWorldMap)
        }
        popup.addAction(loadWorldMap)

        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        popup.addAction(cancelButton)

        viewController?.present(popup, animated: true)
    }

    func showPermissionsPopup() {
        let storyboard = UIStoryboard(name: "RequestPermissionsViewController", bundle: nil)
        let permissionsViewController = storyboard.instantiateViewController(withIdentifier: "requestAlert")
        permissionsViewController.view.translatesAutoresizingMaskIntoConstraints = true
        permissionsViewController.modalPresentationStyle = .overCurrentContext
        permissionsViewController.modalTransitionStyle = .crossDissolve

        viewController?.present(permissionsViewController, animated: true)
    }
    
    func showMessageAboutEnteringXR(_ authorizationRequested: WebXRAuthorizationState, authorizationGranted: @escaping (WebXRAuthorizationState) -> Void, url: URL) {

        weak var blockSelf: MessageController? = self
        let standardUserDefaults = UserDefaults.standard
        let allowedMinimalSites = standardUserDefaults.dictionary(forKey: Constant.allowedMinimalSitesKey())
        let allowedWorldSensingSites = standardUserDefaults.dictionary(forKey: Constant.allowedWorldSensingSitesKey())
        let allowedVideoCameraSites = standardUserDefaults.dictionary(forKey: Constant.allowedVideoCameraSitesKey())
        guard var currentSite: String = url.host else { return }
        webXRAuthorizationRequested = authorizationRequested

        if let port = url.port {
            currentSite = currentSite + ":\(port)"
        }
        site = currentSite

        if !forceShowPermissionsPopup {

            switch authorizationRequested {
            case .minimal:
                standardUserDefaults.set(true, forKey: Constant.minimalWebXREnabled())
                if allowedMinimalSites?[currentSite] != nil {
                    authorizationGranted(.minimal)
                    return
                }
            case .worldSensing:
                standardUserDefaults.set(true, forKey: Constant.minimalWebXREnabled())
                standardUserDefaults.set(true, forKey: Constant.worldSensingWebXREnabled())
                if standardUserDefaults.bool(forKey: Constant.alwaysAllowWorldSensingKey())
                    || allowedWorldSensingSites?[currentSite] != nil
                {
                    authorizationGranted(.worldSensing)
                    return
                }
            case .videoCameraAccess:
                standardUserDefaults.set(true, forKey: Constant.minimalWebXREnabled())
                standardUserDefaults.set(true, forKey: Constant.worldSensingWebXREnabled())
                standardUserDefaults.set(true, forKey: Constant.videoCameraAccessWebXREnabled())
                if allowedVideoCameraSites?[currentSite] != nil {
                    authorizationGranted(.videoCameraAccess)
                    return
                }
            default:
                break
            }
        }

        var height = CGFloat()
        let rowHeight: CGFloat = 44
        switch webXRAuthorizationRequested {
        case .minimal:
            height = rowHeight * 2
        case .lite:
            height = rowHeight * 3
        case .worldSensing:
            height = rowHeight * 3
        case .videoCameraAccess:
            height = rowHeight * 4
        default:
            height = rowHeight * 1
        }
        let storyboard = UIStoryboard(name: "XRRequestXRPermissionsViewController", bundle: nil)
        requestXRPermissionsVC = storyboard.instantiateViewController(withIdentifier: "requestXRAlert") as? RequestXRPermissionsViewController
        guard let requestXRPermissionsVC = requestXRPermissionsVC else { return }
        requestXRPermissionsVC.view.translatesAutoresizingMaskIntoConstraints = true
        requestXRPermissionsVC.tableViewHeightConstraint.constant = height
        requestXRPermissionsVC.tableView.isScrollEnabled = false
        requestXRPermissionsVC.tableView.delegate = self
        requestXRPermissionsVC.tableView.dataSource = self
        requestXRPermissionsVC.tableView.register(UINib(nibName: "XRSwitchInputTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "SwitchInputTableViewCell")
        requestXRPermissionsVC.tableView.register(UINib(nibName: "XRSegmentedControlTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "SegmentedControlTableViewCell")

        var title: String
        var message: String
        switch webXRAuthorizationRequested {
        case .minimal:
            title = "Allow usage of Device Motion?"
            message = "WebXR displays video from your camera without giving this web page access to the video."
        case .lite:
            title = "Allow Lite Mode?"
            message = """
                Lite Mode:
                -Uses a single real world plane
                -Looks for faces
            """
        case .worldSensing:
            title = "Allow World Sensing?"
            message = """
                World Sensing:
                -Uses real world planes & lighting
                -Looks for faces & images
            """
        case .videoCameraAccess:
            title = "Allow Video Camera Access?"
            message = """
                Video Camera Access:
                -Accesses your camera's live image
                -Uses real world planes & lighting
                -Looks for faces & images
            """
        default:
            title = "This site is not requesting WebXR authorization"
            message = "No video from your camera, planes, faces, or things in the real world will be shared with this site."
        }
        requestXRPermissionsVC.titleLabel.text = title
        requestXRPermissionsVC.messageLabel.text = message
        requestXRPermissionsVC.modalPresentationStyle = .overCurrentContext
        requestXRPermissionsVC.modalTransitionStyle = .crossDissolve

        if forceShowPermissionsPopup {
            requestXRPermissionsVC.cancelButton.setTitle("Dismiss", for: .normal)
            requestXRPermissionsVC.cancelButton.addAction(for: .touchUpInside) {
                blockSelf?.viewController?.dismiss(animated: true, completion: nil)
            }
        } else {
            requestXRPermissionsVC.cancelButton.setTitle("Deny", for: .normal)
            requestXRPermissionsVC.cancelButton.addAction(for: .touchUpInside) {
                authorizationGranted(.denied)
                blockSelf?.viewController?.dismiss(animated: true, completion: nil)
            }
        }

        forceShowPermissionsPopup = false

        requestXRPermissionsVC.confirmButton.setTitle("Confirm", for: .normal)
        requestXRPermissionsVC.confirmButton.addAction(for: .touchUpInside) {
            if let minimalCell = blockSelf?.requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? SwitchInputTableViewCell {
                standardUserDefaults.set(minimalCell.switchControl.isOn, forKey: Constant.minimalWebXREnabled())
            }
//            if let liteCell = blockSelf?.requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SwitchInputTableViewCell {
//                standardUserDefaults.set(liteCell.switchControl.isOn, forKey: Constant.liteModeWebXREnabled())
//            }
            if let worldSensingCell = blockSelf?.requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SwitchInputTableViewCell {
                standardUserDefaults.set(worldSensingCell.switchControl.isOn, forKey: Constant.worldSensingWebXREnabled())
            }
            if let videoCameraAccessCell = blockSelf?.requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SwitchInputTableViewCell {
                standardUserDefaults.set(videoCameraAccessCell.switchControl.isOn, forKey: Constant.videoCameraAccessWebXREnabled())
            }

            switch blockSelf?.webXRAuthorizationRequested {
            case .minimal?:
                if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) {
                    guard let minimalControl = blockSelf?.requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SegmentedControlTableViewCell else { return }

                    var newDict = [AnyHashable : Any]()
                    if let dict = allowedMinimalSites {
                        newDict = dict
                    }
                    if minimalControl.segmentedControl.selectedSegmentIndex == 1 {
                        newDict[currentSite] = "YES"
                    } else {
                        newDict[currentSite] = nil
                    }
                    UserDefaults.standard.set(newDict, forKey: Constant.allowedMinimalSitesKey())
                    authorizationGranted(.minimal)
                } else {
                    authorizationGranted(.denied)
                }
            case .lite?:
                authorizationGranted(standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) ? .lite : .denied)
            case .worldSensing?:
                if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.worldSensingWebXREnabled()) {
                    guard let worldControl = blockSelf?.requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SegmentedControlTableViewCell else { return }

                    var newDict = [AnyHashable : Any]()
                    if let dict = allowedWorldSensingSites {
                        newDict = dict
                    }
                    if worldControl.segmentedControl.selectedSegmentIndex == 1 {
                        newDict[currentSite] = "YES"
                    } else {
                        newDict[currentSite] = nil
                    }
                    UserDefaults.standard.set(newDict, forKey: Constant.allowedWorldSensingSitesKey())
                    authorizationGranted(.worldSensing)
                } else if standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) {
                    authorizationGranted(.minimal)
                } else {
                    authorizationGranted(.denied)
                }
            case .videoCameraAccess?:
                if standardUserDefaults.bool(forKey: Constant.videoCameraAccessWebXREnabled()) {
                    guard let videoControl = blockSelf?.requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SegmentedControlTableViewCell else { return }

                    var newDict = [AnyHashable : Any]()
                    if let dict = allowedVideoCameraSites {
                        newDict = dict
                    }
                    if videoControl.segmentedControl.selectedSegmentIndex == 1 {
                        newDict[currentSite] = "YES"
                    } else {
                        newDict[currentSite] = nil
                    }
                    UserDefaults.standard.set(newDict, forKey: Constant.allowedVideoCameraSitesKey())
                    authorizationGranted(.videoCameraAccess)
                } else if standardUserDefaults.bool(forKey: Constant.liteModeWebXREnabled()) {
                    authorizationGranted(.lite)
                } else if standardUserDefaults.bool(forKey: Constant.worldSensingWebXREnabled()) {
                    authorizationGranted(.worldSensing)
                } else if standardUserDefaults.bool(forKey: Constant.minimalWebXREnabled()) {
                    authorizationGranted(.minimal)
                } else {
                    authorizationGranted(.denied)
                }
            default:
                authorizationGranted(.denied)
            }
            blockSelf?.viewController?.dismiss(animated: true, completion: nil)
        }
        permissionsPopup = requestXRPermissionsVC
        viewController?.present(requestXRPermissionsVC, animated: true)
    }
    
    // MARK: - Switch Methods
    
    @objc func switchValueDidChange(sender: UISwitch) {
        // Tony 11/20/19: I'm leaving lots of code commented throughout the repo,
        // including Lite Mode related code, in the event something from prior
        // versions of WebXR Viewer is desired, previous code will still be in-line
        let liteCell = requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 99, section: 0)) as? SwitchInputTableViewCell
        let worldSensingCell = requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SwitchInputTableViewCell
        let videoCameraAccessCell = requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SwitchInputTableViewCell
        let minimalControl = requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? SegmentedControlTableViewCell
        let worldControl = requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 2, section: 0)) as? SegmentedControlTableViewCell
        let videoControl = requestXRPermissionsVC?.tableView.cellForRow(at: IndexPath(row: 3, section: 0)) as? SegmentedControlTableViewCell
        
        switch sender.tag {
        case 0:
            if sender.isOn {
                liteCell?.switchControl.isEnabled = true
                liteCell?.labelTitle.isEnabled = true
                worldSensingCell?.switchControl.isEnabled = true
                worldSensingCell?.labelTitle.isEnabled = true
                minimalControl?.segmentedControl.isEnabled = true
            } else {
                liteCell?.switchControl.setOn(false, animated: true)
                liteCell?.switchControl.isEnabled = false
                liteCell?.labelTitle.isEnabled = false
                worldSensingCell?.switchControl.setOn(false, animated: true)
                worldSensingCell?.switchControl.isEnabled = false
                worldSensingCell?.labelTitle.isEnabled = false
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.labelTitle.isEnabled = false
                minimalControl?.segmentedControl.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            }
        case 1:
            if sender.isOn {
                worldSensingCell?.switchControl.setOn(true, animated: true)
                worldSensingCell?.switchControl.isEnabled = false
                worldSensingCell?.labelTitle.isEnabled = false
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.labelTitle.isEnabled = false
                minimalControl?.segmentedControl.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            } else {
                minimalControl?.segmentedControl.isEnabled = true
                worldSensingCell?.switchControl.isEnabled = true
                worldSensingCell?.labelTitle.isEnabled = true
                worldControl?.segmentedControl.isEnabled = true
                videoCameraAccessCell?.switchControl.isEnabled = true
                videoCameraAccessCell?.labelTitle.isEnabled = true
            }
        case 2:
            if sender.isOn {
                videoCameraAccessCell?.switchControl.isEnabled = true
                videoCameraAccessCell?.labelTitle.isEnabled = true
                worldControl?.segmentedControl.isEnabled = true
            } else {
                videoCameraAccessCell?.switchControl.setOn(false, animated: true)
                videoCameraAccessCell?.switchControl.isEnabled = false
                videoCameraAccessCell?.labelTitle.isEnabled = false
                worldControl?.segmentedControl.isEnabled = false
                videoControl?.segmentedControl.isEnabled = false
            }
        case 3:
            if sender.isOn {
                videoControl?.segmentedControl.isEnabled = true
            } else {
                videoControl?.segmentedControl.isEnabled = false
            }
        default:
            print("Unknown switch control toggled")
        }
    }
    
    // MARK: Alert Controller TableView Functions
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch webXRAuthorizationRequested {
        case .minimal:
            return 2
        case .lite:
            return 3
        case .worldSensing:
            return 3
        case .videoCameraAccess:
            return 4
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
            cell.switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .touchUpInside)
            cell.switchControl.tag = indexPath.row
            cell.labelTitle.text = "Device Motion"
            cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
            
            return cell
        case 1:
            switch webXRAuthorizationRequested {
            case .minimal:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlTableViewCell", for: indexPath) as! SegmentedControlTableViewCell
                cell.segmentedControl.tag = indexPath.row
                
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                {
                    cell.segmentedControl.isEnabled = false
                }
                let allowedMinimalSites = UserDefaults.standard.dictionary(forKey: Constant.allowedMinimalSitesKey())
                if let site = site, allowedMinimalSites?[site] != nil {
                    cell.segmentedControl.selectedSegmentIndex = 1
                }
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                cell.switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .touchUpInside)
                cell.switchControl.tag = indexPath.row
                
                cell.labelTitle.text = "World Sensing"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                {
                    cell.switchControl.isEnabled = false
                    cell.labelTitle.isEnabled = false
                }
                return cell
            }
        case 2:
            switch webXRAuthorizationRequested {
            case .worldSensing:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlTableViewCell", for: indexPath) as! SegmentedControlTableViewCell
                cell.segmentedControl.tag = indexPath.row
                
                if !UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                {
                    cell.segmentedControl.isEnabled = false
                }
                let allowedWorldSensingSites = UserDefaults.standard.dictionary(forKey: Constant.allowedWorldSensingSitesKey())
                if let site = site, allowedWorldSensingSites?[site] != nil {
                    cell.segmentedControl.selectedSegmentIndex = 1
                }
                return cell
            default:
                let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchInputTableViewCell", for: indexPath) as! SwitchInputTableViewCell
                cell.switchControl.addTarget(self, action: #selector(switchValueDidChange(sender:)), for: .touchUpInside)
                cell.switchControl.tag = indexPath.row
                
                cell.labelTitle.text = "Video Camera Access"
                cell.switchControl.isOn = UserDefaults.standard.bool(forKey: Constant.videoCameraAccessWebXREnabled())
                if !UserDefaults.standard.bool(forKey: Constant.minimalWebXREnabled())
                    || UserDefaults.standard.bool(forKey: Constant.liteModeWebXREnabled())
                    || !UserDefaults.standard.bool(forKey: Constant.worldSensingWebXREnabled())
                {
                    cell.switchControl.isEnabled = false
                    cell.labelTitle.isEnabled = false
                }
                return cell
            }
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SegmentedControlTableViewCell", for: indexPath) as! SegmentedControlTableViewCell
            cell.segmentedControl.tag = indexPath.row
            
            if !UserDefaults.standard.bool(forKey: Constant.videoCameraAccessWebXREnabled()) {
                cell.segmentedControl.isEnabled = false
            }
            let allowedVideoCameraSites = UserDefaults.standard.dictionary(forKey: Constant.allowedVideoCameraSitesKey())
            if let site = site, allowedVideoCameraSites?[site] != nil {
                cell.segmentedControl.selectedSegmentIndex = 1
            }
            return cell
        }
    }

    // MARK: Private
    
    @objc func learnMoreLiteModeTapped() {
        let alert = UIAlertController(title: "What's Lite Mode?", message: """
            Lite Mode is privacy-focused and sends less information to WebXR sites.

            When Lite Mode is on, only one real world plane is shared.
            Lite Mode enables face-based experiences, but will not recognize images nor share camera access.
        """, preferredStyle: .alert)
        let ok = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(ok)
        permissionsPopup?.present(alert, animated: true)
    }
}
