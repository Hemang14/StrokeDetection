//
//  VideoCaptureViewController.swift
//  StrokeDetection
//
//  Created by Hemang Singh on 1/22/25.
//

import UIKit
import AVFoundation

class VideoCaptureViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, AVCaptureDepthDataOutputDelegate {
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
            
            configureHighSpeedVideoSettings(videoDevice)
            
            movieOutput = AVCaptureMovieFileOutput()
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
        } catch {
            print("Error setting device input/output: \(error)")
        }
    }

    private func configureHighSpeedVideoSettings(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()

            // Find and apply the highest frame rate video format.
            let formats = device.formats.filter { $0.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 120 } }
            if let format = formats.first, let range = format.videoSupportedFrameRateRanges.first(where: { $0.maxFrameRate >= 120 }) {
                device.activeFormat = format
                device.activeVideoMinFrameDuration = range.minFrameDuration
                device.activeVideoMaxFrameDuration = range.minFrameDuration
            }

            // Configure exposure settings for fast motion capture.
            if device.isExposureModeSupported(.custom) {
                let exposureDuration = CMTimeMake(value: 1, timescale: 1000) // 1/1000 seconds
                device.setExposureModeCustom(duration: exposureDuration, iso: AVCaptureDevice.currentISO, completionHandler: nil)
            }

            device.unlockForConfiguration()
        } catch {
            print("Error configuring the device for high-speed video: \(error)")
        }
    }
    
    /* /// This can be used to capture video in high quality - 1080*1920
     private func configureHighSpeedVideoSettings(_ device: AVCaptureDevice) {
         do {
             try device.lockForConfiguration()

             // Identify the best format that supports 1080p at the highest frame rate
             var bestFormat: AVCaptureDevice.Format?
             var highestFrameRate: AVFrameRateRange?

             for format in device.formats {
                 if format.formatDescription.dimensions.width == 1920 && format.formatDescription.dimensions.height == 1080 {
                     for range in format.videoSupportedFrameRateRanges {
                         if highestFrameRate == nil || range.maxFrameRate > highestFrameRate!.maxFrameRate {
                             highestFrameRate = range
                             bestFormat = format
                         }
                     }
                 }
             }

             if let bestFormat = bestFormat, let highestFrameRate = highestFrameRate {
                 // Set the device's active format
                 device.activeFormat = bestFormat
                 device.activeVideoMinFrameDuration = highestFrameRate.minFrameDuration
                 device.activeVideoMaxFrameDuration = highestFrameRate.minFrameDuration

                 // Adjust exposure settings for rapid movements
                 if device.isExposureModeSupported(.custom) {
                     let exposureDuration = highestFrameRate.minFrameDuration
                     device.setExposureModeCustom(duration: exposureDuration, iso: AVCaptureDevice.currentISO, completionHandler: nil)
                 }

                 device.unlockForConfiguration()
             } else {
                 print("No suitable format found for 1080p recording at a high frame rate.")
             }
         } catch {
             print("Error configuring the device for high-speed video: \(error)")
             device.unlockForConfiguration()
         }
     }

     */

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

    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        // Process depth data
        let depthPixelBuffer = depthData.depthDataMap
        processDepthData(pixelBuffer: depthPixelBuffer)
    }
    
    private func processDepthData(pixelBuffer: CVPixelBuffer) {
        // Placeholder for depth data processing
    }
}
