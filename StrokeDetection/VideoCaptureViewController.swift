//
//  VideoCaptureViewController.swift
//  StrokeDetection
//
//  Created by Hemang Singh on 1/22/25.
//
import UIKit
import AVFoundation

class VideoCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    var captureSession: AVCaptureSession!
    var activeInput: AVCaptureDeviceInput!
    var movieOutput: AVCaptureMovieFileOutput!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var outputURL: URL!
    var recordButton: UIButton!
    var depthDataOutput: AVCaptureDepthDataOutput!


    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
//        setupPreview()   // Setup preview first
        setupRecordButton()  // Then, setup record button
    }


    private func setupRecordButton() {
        recordButton = UIButton(type: .system)
        recordButton.frame = CGRect(x: (view.bounds.width - 120) / 2, y: view.bounds.height - 80, width: 120, height: 50)
        recordButton.backgroundColor = .red
        recordButton.setTitle("Record", for: .normal)
        recordButton.setTitleColor(.white, for: .normal)
        recordButton.layer.cornerRadius = 25
        recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
        recordButton.autoresizingMask = [.flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]

        // Ensure the button is above all other views
        view.addSubview(recordButton)
        view.bringSubviewToFront(recordButton)
    }


    @objc func toggleRecording() {
        if movieOutput.isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        if captureSession.canSetSessionPreset(.photo) {
            captureSession.sessionPreset = .photo  // This is necessary to capture depth data
        }

        setupDeviceInputAndOutput()
        setupDepthDataOutput()  // Setup depth data output
        setupPreview()
        captureSession.startRunning()
    }

    private func setupDepthDataOutput() {
        depthDataOutput = AVCaptureDepthDataOutput()
        depthDataOutput.isFilteringEnabled = true  // Use depth data filtering to smooth depth data
        
        if captureSession.canAddOutput(depthDataOutput) {
            captureSession.addOutput(depthDataOutput)
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = true
            }
        }
        
        depthDataOutput.setDelegate(self, callbackQueue: DispatchQueue(label: "depthDataQueue"))
    }

    private func isDepthCaptureSupported() -> Bool {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            return false
        }
        return device.activeFormat.supportedDepthDataFormats.count > 0
    }

    private func setupDeviceInputAndOutput() {
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("Devices are not available.")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                activeInput = videoInput
            }
            
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            
            configureVideoInputSettings(videoDevice)
            
            movieOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
        } catch {
            print("Error setting device input/output: \(error)")
        }
    }
    
    private func configureVideoInputSettings(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            if device.isSmoothAutoFocusEnabled {
                device.isSmoothAutoFocusEnabled = true
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring the device: \(error)")
        }
    }


    private func setupPreview() {
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.insertSublayer(previewLayer, at: 0)
    }

    func startRecording() {
        if !movieOutput.isRecording {
            let connection = movieOutput.connection(with: .video)
            if connection?.isVideoOrientationSupported ?? false {
                connection?.videoOrientation = .portrait
            }
            outputURL = URL(fileURLWithPath: NSTemporaryDirectory() + UUID().uuidString + ".mp4")
            movieOutput.startRecording(to: outputURL, recordingDelegate: self)
            DispatchQueue.main.async {
                self.recordButton.setTitle("Stop", for: .normal)
                self.recordButton.backgroundColor = .green
            }
        }
    }

    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            DispatchQueue.main.async {
                self.recordButton.setTitle("Record", for: .normal)
                self.recordButton.backgroundColor = .red
            }
        }
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording movie: \(error.localizedDescription)")
        } else {
            let videoRecorded = outputFileURL
            print("Recording finished: \(videoRecorded)")
            UISaveVideoAtPathToSavedPhotosAlbum(videoRecorded.path, nil, nil, nil)
        }
    }
}

extension VideoCaptureViewController: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        // Process depth data
        let depthPixelBuffer = depthData.depthDataMap
        processDepthData(pixelBuffer: depthPixelBuffer)
    }
    
    private func processDepthData(pixelBuffer: CVPixelBuffer) {
        // We can use this later for processing the video and depth
    }
}

