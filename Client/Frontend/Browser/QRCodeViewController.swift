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
    static let maskViewBackgroungColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    static let isLightingNavigationItemColor = UIColor(red: 0.45, green: 0.67, blue: 0.84, alpha: 1)
}

protocol QRCodeViewControllerDelegate {
    func scanSuccessOpenNewTabWithData(data: String)
}

class QRCodeViewController: UIViewController {
    var qrCodeDelegate: QRCodeViewControllerDelegate?

    fileprivate lazy var captureSession: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = AVCaptureSessionPresetHigh
        return session
    }()

    private lazy var captureDevice: AVCaptureDevice? = {
        return AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    }()

    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
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
    private var isAnimationing: Bool = false
    private var isLightOn: Bool = false
    private var shapeLayer: CAShapeLayer = CAShapeLayer()

    private var scanRange: CGRect {
        let size = UIDevice.current.userInterfaceIdiom == .pad ?
            CGSize(width: view.frame.width / 2, height: view.frame.width / 2) :
            CGSize(width: view.frame.width / 3 * 2, height: view.frame.width / 3 * 2)
        var rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        rect.center = UIScreen.main.bounds.center
        return rect
    }

    private var scanBorderHeight: CGFloat {
        return UIDevice.current.userInterfaceIdiom == .pad ?
            view.frame.width / 2 : view.frame.width / 3 * 2
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let captureDevice = self.captureDevice else {
            dismiss(animated: false)
            return
        }

        self.navigationItem.title = Strings.ScanQRCodeViewTitle

        // Setup the NavigationBar
        self.navigationController?.navigationBar.barTintColor = QRCodeViewControllerUX.navigationBarBackgroundColor
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: QRCodeViewControllerUX.navigationBarTitleColor]

        // Setup the NavigationItem
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "qrcode-goBack"), style: UIBarButtonItemStyle.plain, target: self, action: #selector(goBack))
        self.navigationItem.leftBarButtonItem?.tintColor = UIColor.white

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "qrcode-light"), style: .plain, target: self, action: #selector(openLight))
        if captureDevice.hasTorch {
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.white
        } else {
            self.navigationItem.rightBarButtonItem?.tintColor = UIColor.gray
            self.navigationItem.rightBarButtonItem?.isEnabled = false
        }

        let getAuthorizationStatus = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
        if getAuthorizationStatus != AVAuthorizationStatus.denied {
            setupCamera()
        } else {
            let alert = UIAlertController(title: "", message: Strings.ScanQRCodePermissionErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.ScanQRCodeErrorOKButton, style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }

        maskView.backgroundColor = QRCodeViewControllerUX.maskViewBackgroungColor
        self.view.addSubview(maskView)
        self.view.addSubview(scanBorder)
        self.view.addSubview(scanLine)
        self.view.addSubview(instructionsLabel)

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
                make.top.equalTo(self.scanBorder.snp.top).offset(self.scanBorderHeight - 6)
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
        guard let captureDevice = self.captureDevice else {
            return
        }

        if isLightOn {
            do {
                try captureDevice.lockForConfiguration()
                captureDevice.torchMode = AVCaptureTorchMode.off
                captureDevice.unlockForConfiguration()
                navigationItem.rightBarButtonItem?.image = UIImage(named: "qrcode-light")
                navigationItem.rightBarButtonItem?.tintColor = UIColor.white
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
        guard let captureDevice = self.captureDevice else {
            dismiss(animated: false)
            return
        }

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
        if let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer.frame = UIScreen.main.bounds
            view.layer.addSublayer(videoPreviewLayer)
            self.videoPreviewLayer = videoPreviewLayer
            captureSession.startRunning()
        }
    }

    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        shapeLayer.removeFromSuperlayer()
        let rectPath = UIBezierPath(rect: UIScreen.main.bounds)
        rectPath.append(UIBezierPath(rect: scanRange).reversing())
        shapeLayer.path = rectPath.cgPath
        maskView.layer.mask = shapeLayer

        guard let videoPreviewLayer = self.videoPreviewLayer else {
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

extension QRCodeViewController: AVCaptureMetadataOutputObjectsDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        if metadataObjects == nil || metadataObjects.count == 0 {
            self.captureSession.stopRunning()
            let alert = UIAlertController(title: "", message: Strings.ScanQRCodeInvalidDataErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Strings.ScanQRCodeErrorOKButton, style: .default, handler: { (UIAlertAction) in
                self.captureSession.startRunning()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.captureSession.stopRunning()
            stopScanLineAnimation()
            self.dismiss(animated: true, completion: {
                guard let metaData = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let qrCodeDelegate = self.qrCodeDelegate else {
                        Sentry.shared.sendWithStacktrace(message: "Unable to scan QR code", tag: .general)
                        return
                }
                qrCodeDelegate.scanSuccessOpenNewTabWithData(data: metaData.stringValue)
            })
        }
    }
}

class QRCodeNavigationController: UINavigationController {
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}
