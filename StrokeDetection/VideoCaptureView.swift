////
////  VideoCaptureView.swift
////  StrokeDetection
////
////  Created by Hemang Singh on 1/22/25.
////

import SwiftUI

struct VideoCaptureView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> VideoCaptureViewController {
        VideoCaptureViewController()
    }

    func updateUIViewController(_ uiViewController: VideoCaptureViewController, context: Context) {
    }
}
