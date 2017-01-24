/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AVFoundation
import SnapKit

private struct QRCodeViewControllerUX {
    static let navigationBarBackgroundColor = UIColor.blackColor()
    static let navigationBarTitleColor = UIColor.whiteColor()
    static let maskViewBackgroungColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.5)
    static let isLightingNavigationItemColor = UIColor(colorLiteralRed: 0.45, green: 0.67, blue: 0.84, alpha: 1)
}

protocol QRCodeViewControllerDelegate {
    func scanSuccessOpenNewTab(url: NSURL)
}

class QRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var qrCodeDelegate: QRCodeViewControllerDelegate?
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        return session
    }()
    
    private lazy var captureDevice: AVCaptureDevice = {
        let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        return device
    }()
    
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let scanLine: UIImageView = UIImageView(image: UIImage(named: "qrcode-scanLine"))
    private let scanBorder: UIImageView = UIImageView(image: UIImage(named: "qrcode-scanBorder"))
    private lazy var instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("Align QR Code within frame to scan", comment: "Text for the Label, displayed in the QRCodeViewController")
        label.textColor = UIColor.whiteColor()
        label.textAlignment = NSTextAlignment.Center
        return label
    }()
    private var maskView: UIView = UIView()
    private var scanRange: CGRect!
    private var isAnimationing: Bool = false
    private var isLightOn: Bool = false
    private var scanBorderHeight: CGFloat!
    private var shapeLayer: CAShapeLayer = CAShapeLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString("QR Code", comment: "Title for the navigationItem")
        
        // Setup the NavigationBar
        self.navigationController?.navigationBar.barTintColor = QRCodeViewControllerUX.navigationBarBackgroundColor
        let navigationTitleAttribute: NSDictionary = NSDictionary(object: QRCodeViewControllerUX.navigationBarTitleColor, forKey: NSForegroundColorAttributeName)
        self.navigationController?.navigationBar.titleTextAttributes = (navigationTitleAttribute as! [String : AnyObject])
        
        // Setup the NavigationItem
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "qrcode-goBack"), style: UIBarButtonItemStyle.Plain, target: self, action: #selector(goBack))
        self.navigationItem.leftBarButtonItem!.tintColor = UIColor.whiteColor()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "qrcode-light"), style: .Plain, target: self, action: #selector(openLight))
        
        if captureDevice.hasTorch {
            self.navigationItem.rightBarButtonItem!.tintColor = UIColor.whiteColor()
        } else {
            self.navigationItem.rightBarButtonItem!.tintColor = UIColor.grayColor()
            self.navigationItem.rightBarButtonItem!.enabled = false
        }
        
        let getAuthorizationStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        if getAuthorizationStatus != AVAuthorizationStatus.Denied {
            setupCamera()
        } else {
            let alert = UIAlertController(title: "", message: NSLocalizedString("Please allow Firefox to access your device's camera in 'Settings' -> 'Privacy' -> 'Camera'.", comment: "Text of the prompt user to setup the camera authorization."), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
        maskView.backgroundColor = QRCodeViewControllerUX.maskViewBackgroungColor
        self.view.addSubview(maskView)
        self.view.addSubview(scanBorder)
        self.view.addSubview(scanLine)
        self.view.addSubview(instructionsLabel)
        
        scanRange = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? CGRectMake(0, 0, view.frame.width / 2, view.frame.width / 2) : CGRectMake(0, 0, view.frame.width / 3 * 2, view.frame.width / 3 * 2)
        scanRange.center = UIScreen.mainScreen().bounds.center
        scanBorderHeight = UIDevice.currentDevice().userInterfaceIdiom == .Pad ? view.frame.width / 2 : view.frame.width / 3 * 2
        
        setupConstraints()
        let rectPath = UIBezierPath(rect: UIScreen.mainScreen().bounds)
        rectPath.appendPath(UIBezierPath(rect: scanRange).bezierPathByReversingPath())
        shapeLayer.path = rectPath.CGPath
        maskView.layer.mask = shapeLayer
        
        isAnimationing = true
        startScanLineAnimation()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
        stopScanLineAnimation()
    }
    
    private func setupConstraints() {
        maskView.snp_makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            scanBorder.snp_makeConstraints { (make) in
                make.center.equalTo(0)
                make.width.height.equalTo(view.frame.width / 2)
            }
        } else {
            scanBorder.snp_makeConstraints { (make) in
                make.center.equalTo(0)
                make.width.height.equalTo(view.frame.width / 3 * 2)
            }
        }
        
        scanLine.snp_makeConstraints { (make) in
            make.left.equalTo(scanBorder.snp_left)
            make.top.equalTo(scanBorder.snp_top).offset(6)
            make.width.equalTo(scanBorder.snp_width)
            make.height.equalTo(6)
        }
        
        instructionsLabel.snp_makeConstraints { (make) in
            make.left.right.equalTo(0)
            make.top.equalTo(scanBorder.snp_bottom).offset(30)
            make.height.equalTo(50)
        }
    }
    
    func startScanLineAnimation() {
        if (!isAnimationing) {
            return
        }
        self.view.layoutIfNeeded()
        self.view.setNeedsLayout()
        UIView.animateWithDuration(2.4, animations: {
            self.scanLine.snp_updateConstraints(closure: { (make) in
                make.top.equalTo(self.scanBorder.snp_top).offset(self.scanBorderHeight! - 6)
            })
            self.view.layoutIfNeeded()
        }) { (value: Bool) in
            self.scanLine.snp_updateConstraints(closure: { (make) in
                make.top.equalTo(self.scanBorder.snp_top).offset(6)
            })
            self.performSelector(#selector(self.startScanLineAnimation), withObject: nil, afterDelay: 0)
        }
    }
    
    func stopScanLineAnimation() {
        isAnimationing = false
    }
    
    func goBack() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func openLight() {
        if isLightOn {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = AVCaptureTorchMode.Off
                captureDevice.unlockForConfiguration()
                navigationItem.rightBarButtonItem?.image = UIImage(named: "qrcode-light")
                navigationItem.rightBarButtonItem!.tintColor = UIColor.whiteColor()
            } catch {
                print(error)
            }
        } else {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = AVCaptureTorchMode.On
                captureDevice.unlockForConfiguration()
                navigationItem.rightBarButtonItem?.image = UIImage(named: "qrcode-isLighting")
                navigationItem.rightBarButtonItem?.tintColor = QRCodeViewControllerUX.isLightingNavigationItemColor
            } catch {
                print(error)
            }
        }
        isLightOn = !isLightOn
    }
    
    func setupCamera() {
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            print(error)
        }
        
        let output = AVCaptureMetadataOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = UIScreen.mainScreen().bounds
        view.layer.addSublayer(previewLayer!)
        
        captureSession.startRunning()
    }
    
    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0 {
            self.captureSession.stopRunning()
            let alert = UIAlertController(title: "", message: NSLocalizedString("The data is invalid", comment: "Text of the prompt user the data is invalid"), preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .Default, handler: { (UIAlertAction) in
                self.captureSession.startRunning()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        } else {
            self.captureSession.stopRunning()
            stopScanLineAnimation()
            let metaData = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            let url = NSURL(string: metaData.stringValue)
            self.dismissViewControllerAnimated(true, completion: {
                self.qrCodeDelegate!.scanSuccessOpenNewTab(url!)
            })
        }
    }
    
    override func willAnimateRotationToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        shapeLayer.removeFromSuperlayer()
        scanRange.center = UIScreen.mainScreen().bounds.center
        let rectPath = UIBezierPath(rect: UIScreen.mainScreen().bounds)
        rectPath.appendPath(UIBezierPath(rect: scanRange).bezierPathByReversingPath())
        shapeLayer.path = rectPath.CGPath
        maskView.layer.mask = shapeLayer
        
        guard let videoPreviewLayer = previewLayer else {
            return
        }
        videoPreviewLayer.frame = UIScreen.mainScreen().bounds
        switch toInterfaceOrientation {
        case .Portrait:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        case .LandscapeLeft:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
        case .LandscapeRight:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
        case .PortraitUpsideDown:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.PortraitUpsideDown
        default:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
        }
    }
}

extension UINavigationController {
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
