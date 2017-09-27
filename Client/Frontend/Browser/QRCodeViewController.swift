/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AVFoundation
import SnapKit
import Shared

private struct QRCodeViewControllerUX {
    static let navigationBarBackgroundColor = UIColor.black
    static let navigationBarTitleColor = UIColor.white
    static let maskViewBackgroungColor = UIColor(colorLiteralRed: 0, green: 0, blue: 0, alpha: 0.5)
    static let isLightingNavigationItemColor = UIColor(colorLiteralRed: 0.45, green: 0.67, blue: 0.84, alpha: 1)
}

protocol QRCodeViewControllerDelegate {
    func scanSuccessOpenNewTabWithData(data: String)
}

class QRCodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var qrCodeDelegate: QRCodeViewControllerDelegate?
    private lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        return session
    }()

    private lazy var captureDevice: AVCaptureDevice = {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        return device!
    }()

    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let scanLine: UIImageView = UIImageView(image: UIImage(named: "qrcode-scanLine"))
    private let scanBorder: UIImageView = UIImageView(image: UIImage(named: "qrcode-scanBorder"))
    private lazy var instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = Strings.ScanQRCodeInstructionsLabel
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        label.numberOfLines = 0
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
        self.navigationItem.title = Strings.ScanQRCodeViewTitle

        // Setup the NavigationBar
        self.navigationController?.navigationBar.barTintColor = QRCodeViewControllerUX.navigationBarBackgroundColor
        let navigationTitleAttribute: NSDictionary = NSDictionary(object: QRCodeViewControllerUX.navigationBarTitleColor, forKey: NSForegroundColorAttributeName as NSCopying)
        self.navigationController?.navigationBar.titleTextAttributes = (navigationTitleAttribute as! [String : AnyObject])

        // Setup the NavigationItem
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "qrcode-goBack"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(goBack))
        self.navigationItem.leftBarButtonItem!.tintColor = UIColor.white

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "qrcode-light"), style: .plain, target: self, action: #selector(openLight))
        if captureDevice.hasTorch {
            self.navigationItem.rightBarButtonItem!.tintColor = UIColor.white
        } else {
            self.navigationItem.rightBarButtonItem!.tintColor = UIColor.gray
            self.navigationItem.rightBarButtonItem!.isEnabled = false
        }

        let getAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if getAuthorizationStatus != AVAuthorizationStatus.denied {
            setupCamera()
        } else {
            let alert = UIAlertController(title: "", message: NSLocalizedString("Please allow Firefox to access your device’s camera in ‘Settings’ -> ‘Privacy’ -> ‘Camera’.", comment: "Text of the prompt user to setup the camera authorization."), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        maskView.backgroundColor = QRCodeViewControllerUX.maskViewBackgroungColor
        self.view.addSubview(maskView)
        self.view.addSubview(scanBorder)
        self.view.addSubview(scanLine)
        self.view.addSubview(instructionsLabel)

        scanRange = UIDevice.current.userInterfaceIdiom == .pad ? CGRect(x: 0, y: 0, width: view.frame.width / 2, height:  view.frame.width / 2) : CGRect(x: 0, y: 0, width:  view.frame.width / 3 * 2, height:  view.frame.width / 3 * 2)

        scanRange.center = UIScreen.main.bounds.center
        scanBorderHeight = UIDevice.current.userInterfaceIdiom == .pad ? view.frame.width / 2 : view.frame.width / 3 * 2

        setupConstraints()
        let rectPath = UIBezierPath(rect: UIScreen.main.bounds)
        rectPath.append(UIBezierPath(rect: scanRange).reversing())
        shapeLayer.path = rectPath.cgPath
        maskView.layer.mask = shapeLayer

        isAnimationing = true
        startScanLineAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
        stopScanLineAnimation()
    }

    private func setupConstraints() {
        maskView.snp.makeConstraints { (make) in
            make.edges.equalTo(self.view)
        }
        if UIDevice.current.userInterfaceIdiom == .pad {
            scanBorder.snp.makeConstraints { (make) in
                make.center.equalTo(self.view)
                make.width.height.equalTo(view.frame.width / 2)
            }
        } else {
            scanBorder.snp.makeConstraints { (make) in
                make.center.equalTo(self.view)
                make.width.height.equalTo(view.frame.width / 3 * 2)
            }
        }
        scanLine.snp.makeConstraints { (make) in
            make.left.equalTo(scanBorder.snp.left)
            make.top.equalTo(scanBorder.snp.top).offset(6)
            make.width.equalTo(scanBorder.snp.width)
            make.height.equalTo(6)
        }

        instructionsLabel.snp.makeConstraints { (make) in
            make.left.right.equalTo(self.view.layoutMarginsGuide)
            make.top.equalTo(scanBorder.snp.bottom).offset(30)
        }
    }

    func startScanLineAnimation() {
        if !isAnimationing {
            return
        }
        self.view.layoutIfNeeded()
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 2.4, animations: {
            self.scanLine.snp.updateConstraints({ (make) in
                make.top.equalTo(self.scanBorder.snp.top).offset(self.scanBorderHeight! - 6)
            })
            self.view.layoutIfNeeded()
        }) { (value: Bool) in
            self.scanLine.snp.updateConstraints({ (make) in
                make.top.equalTo(self.scanBorder.snp.top).offset(6)
            })
            self.perform(#selector(self.startScanLineAnimation), with: nil, afterDelay: 0)
        }
    }

    func stopScanLineAnimation() {
        isAnimationing = false
    }

    func goBack() {
        self.dismiss(animated: true, completion: nil)
    }

    func openLight() {
        if isLightOn {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = AVCaptureTorchMode.off
                captureDevice.unlockForConfiguration()
                navigationItem.rightBarButtonItem?.image = UIImage(named: "qrcode-light")
                navigationItem.rightBarButtonItem!.tintColor = UIColor.white
            } catch {
                print(error)
            }
        } else {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = AVCaptureTorchMode.on
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
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            output.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
        }
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewLayer?.frame = UIScreen.main.bounds
        view.layer.addSublayer(previewLayer!)
        captureSession.startRunning()
    }

    // MARK: - AVCaptureMetadataOutputObjectsDelegate
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0 {
            self.captureSession.stopRunning()
            let alert = UIAlertController(title: "", message: NSLocalizedString("The data is invalid", comment: "Text of the prompt user the data is invalid"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK button"), style: .default, handler: { (UIAlertAction) in
                self.captureSession.startRunning()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.captureSession.stopRunning()
            stopScanLineAnimation()
            let metaData = metadataObjects.first as! AVMetadataMachineReadableCodeObject
            self.dismiss(animated: true, completion: {
                self.qrCodeDelegate!.scanSuccessOpenNewTabWithData(data: metaData.stringValue)
            })
        }
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        shapeLayer.removeFromSuperlayer()
        scanRange.center = UIScreen.main.bounds.center
        let rectPath = UIBezierPath(rect: UIScreen.main.bounds)
        rectPath.append(UIBezierPath(rect: scanRange).reversing())
        shapeLayer.path = rectPath.cgPath
        maskView.layer.mask = shapeLayer

        guard let videoPreviewLayer = previewLayer else {
            return
        }
        videoPreviewLayer.frame = UIScreen.main.bounds
        switch toInterfaceOrientation {
        case .portrait:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
        case .landscapeLeft:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
        case .landscapeRight:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
        case .portraitUpsideDown:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portraitUpsideDown
        default:
            videoPreviewLayer.connection.videoOrientation = AVCaptureVideoOrientation.portrait
        }
    }
}

extension UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
