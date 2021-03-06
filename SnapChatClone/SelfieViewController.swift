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

class SelfieViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    /*********************************************************************************************
     *  Views
     *********************************************************************************************/
    
    @IBOutlet weak var flipCameraButton: UIButton!
    
    var recordingButton: RecordButton!
    
    /*********************************************************************************************
     *  Constants
     *********************************************************************************************/
    
    // Video save settings
    static let outputSettings = [
        AVVideoWidthKey: Int(480),
        AVVideoHeightKey: Int(640),
        AVVideoCodecKey: AVVideoCodecH264
        ] as [String : Any]
    
    /*********************************************************************************************
     *  Properties
     *********************************************************************************************/
    
    // AVFoundation
    var cameraSession: AVCaptureSession?
    var assetWriterInput: AVAssetWriterInput?
    var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?
    
    // Recording button variables
    var progressTimer: Timer!
    var progress: CGFloat! = 0
    let maxDuration: CGFloat! = 10 // 10 seconds
    
    /*********************************************************************************************
     *  LifeCycle Methods
     *********************************************************************************************/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.black

        // Prepare views here
        prepareRecordingButton()
        prepareCameraSession()
        prepareCameraPreviewLayer()
        
        // Start our camera session
        startCameraSession()
    }
    
    /*********************************************************************************************
     *  AVCaptureVideoDataOutputSampleBufferDelegate Methods
     *********************************************************************************************/
    
    fileprivate func startCameraSession() {
        
        // Get our front facing camera
        let captureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) as AVCaptureDevice
        
        do {
            
            // Set our device input type
            let deviceInputType = try AVCaptureDeviceInput(device: captureDevice)
            
            // Indicates start of a set of configurations to be done atomically -
            cameraSession?.beginConfiguration()
            
            if (cameraSession?.canAddInput(deviceInputType) == true) {
                cameraSession?.addInput(deviceInputType)
            }
            
            // Go ahead and set video properties by creating a new instantiation of AVCaptureVideoDataOutput
            let dataOutput = AVCaptureVideoDataOutput()
            
            // This pixel format is composed by two 8-bit components. The first byte represents the luma, while the second byte represents two chroma components (blue and red). This format is also shortly called YCC.
            // Used since processing video frames is computationally expensive so using this format helps
            dataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString): NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange as UInt32)]
            
            // Discard vidoe frames to process video faster
            // If the video frame arrives too late discard it
            dataOutput.alwaysDiscardsLateVideoFrames = true
            
            if (cameraSession?.canAddOutput(dataOutput) == true) {
                cameraSession?.addOutput(dataOutput)
            }
            
            cameraSession?.commitConfiguration()
            
            let queue = DispatchQueue(label: "video_queue")
            dataOutput.setSampleBufferDelegate(self, queue: queue)
            
        } catch let error as NSError {
            NSLog("\(error)", "\(error.localizedDescription)")
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        // Here you collect each frame and process it into a video file if you want, send it up to the server foolio...
        
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        
        // Here you can collect the frames that were dropped foolio...
        
    }

    
    /*********************************************************************************************
     *  IBAction Functions
     *********************************************************************************************/
    
    @IBAction func flipCameraPressed(_ sender: UIButton) {
        
        // Flip our camera
        if let session = cameraSession {
            
            // Let the session know we are about to start making changes
            session.beginConfiguration()
            
            // Remove existing input
            let currentCameraInput: AVCaptureInput = session.inputs.first as! AVCaptureInput
            session.removeInput(currentCameraInput)
            
            // Declare our new camera variable
            var newCamera: AVCaptureDevice! = nil
            
            // Get the new input, so back or front camera
            if let input = currentCameraInput as? AVCaptureDeviceInput {
                newCamera = input.device.position == .front ? cameraWithPosition(position: .back) : cameraWithPosition(position: .front)
            }
            
            // Create a new input to this session
            var err: NSError?
            var newVideoInput: AVCaptureDeviceInput!
            do {
                newVideoInput = try AVCaptureDeviceInput(device: newCamera)
            } catch let err1 as NSError {
                err = err1
                newVideoInput = nil
            }
            
            // Add the input here to the session or show an error
            if (newVideoInput == nil || err != nil) {
                print("Error creating capture device input: \(err!.localizedDescription)")
            } else {
                session.addInput(newVideoInput)
            }
            
            // Commit all of our configuration changes
            session.commitConfiguration()
        }
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
    
    /*********************************************************************************************
     *  Accessory Functions
     *********************************************************************************************/
    
    fileprivate func bringSubviewsToFront() {
        
        // After starting our camera layer we need to bring the subviews to the front
        self.view.bringSubview(toFront: self.recordingButton)
        self.view.bringSubview(toFront: self.flipCameraButton)
    }
    
    fileprivate func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice? {
        
        // Get our list of devices
        let devices = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)!
        for device in devices {
            let device = device as! AVCaptureDevice
            if device.position == position {
                return device
            }
        }
        
        return nil
    }

}

extension SelfieViewController {
    
    fileprivate func prepareRecordingButton() {
        
        // Create a new button and set it's attributes and targets
        self.recordingButton = RecordButton(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        self.recordingButton.progressColor = UIColor(red:0.96, green:0.89, blue:0.23, alpha:1.00)
        self.recordingButton.buttonColor = UIColor(red:0.96, green:0.89, blue:0.23, alpha:1.00) // SnapChat Button
        self.recordingButton.closeWhenFinished = false
        
        // Set targets
        self.recordingButton.addTarget(self, action: #selector(record), for: .touchDown)
        self.recordingButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        
        // Remove our autoresizing mask
        self.recordingButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Add to the main view
        self.view.addSubview(self.recordingButton)
        
        // Activate layout constraints
        let bottomConstraint = NSLayoutConstraint(item: recordingButton, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1.0, constant: -50)
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
        
        // Go ahead and add the camera preview layer to the next index
        self.view.layer.addSublayer(preview!)
        
        // Bring our recording button to the front
        bringSubviewsToFront()
        
        // Prepare our asset writers to save media
        // TODO...
        
        // Start the camera session
        self.cameraSession?.startRunning()
    }

}
