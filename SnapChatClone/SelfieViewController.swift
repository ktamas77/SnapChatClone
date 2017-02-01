//
//  SelfieViewController.swift
//  SnapChatClone
//
//  Created by Haider Khan on 2/1/17.
//  Copyright © 2017 ZkHaider. All rights reserved.
//

import UIKit
import AVFoundation
import RecordButton

class SelfieViewController: UIViewController {
    
    /*********************************************************************************************
     *  Views
     *********************************************************************************************/
    
    weak var recordingButton: RecordButton!
    
    /*********************************************************************************************
     *  Properties
     *********************************************************************************************/
    
    // AVFoundation
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var cameraSession: AVCaptureSession?
    
    // Recording button variables
    var progressTimer: Timer!
    var progress: CGFloat! = 0
    let maxDuration: CGFloat! = 10 // 10 seconds
    
    /*********************************************************************************************
     *  LifeCycle Methods
     *********************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Prepare views here
        prepareRecordingButton()
        prepareCameraSession()
        prepareCameraPreviewLayer()
    }
    
    /*********************************************************************************************
     *  Target Functions
     *********************************************************************************************/

    @objc func record() {
        self.progressTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    
    @objc func stop() {
        self.progressTimer.invalidate()
    }
    
    @objc func updateProgress() {
        
        progress = progress + (CGFloat(0.15) / maxDuration)
        self.recordingButton.setProgress(progress)
        
        if progress >= 1 {
            self.progress = 0
            self.recordingButton.setProgress(progress)
            self.progressTimer.invalidate()
        }
    }

}

extension SelfieViewController {
    
    fileprivate func prepareRecordingButton() {
        
        // Create a new button and set it's attributes and targets
        self.recordingButton = RecordButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        self.recordingButton.buttonColor = UIColor.white
        self.recordingButton.closeWhenFinished = false
        
        // Set targets
        self.recordingButton.addTarget(self, action: #selector(record), for: .touchDown)
        self.recordingButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        
        // Remove our autoresizing mask
        self.recordingButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to the main view
        self.view.addSubview(self.recordingButton)
        
        // Activate layout constraints
        let bottomConstraint = NSLayoutConstraint(item: recordingButton, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: 100)
        let centerHorizontalConstraint = NSLayoutConstraint(item: recordingButton, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1.0, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: recordingButton, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70)
        let widthConstraint = NSLayoutConstraint(item: recordingButton, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 70)
        NSLayoutConstraint.activate([bottomConstraint, centerHorizontalConstraint, heightConstraint, widthConstraint])
    }
    
    fileprivate func prepareCameraSession() {
        
        // Initialize a new camera session
        cameraSession = AVCaptureSession()
        cameraSession?.sessionPreset = AVCaptureSessionPresetHigh
    }
    
    fileprivate func prepareCameraPreviewLayer() {
        
        let preview = AVCaptureVideoPreviewLayer(session: self.cameraSession)
        preview?.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: self.view.bounds.height)
        preview?.position = CGPoint(x: self.view.bounds.midX, y: self.view.bounds.midY)
        preview?.videoGravity = AVLayerVideoGravityResize
        
        // Remove player video
        self.playerLayer?.removeFromSuperlayer()
        
        // Go ahead and add the camera preview layer to the next index
        self.view.layer.addSublayer(preview!)
        
        // Bring our recording button to the front
        self.view.bringSubview(toFront: recordingButton)
        
        // Start the camera session
        self.cameraSession?.startRunning()
    }

}