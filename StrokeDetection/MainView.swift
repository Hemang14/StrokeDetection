//
//  MainView.swift
//  StrokeDetection
//
//  Created by Hemang Singh on 1/22/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Record Video")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                NavigationLink(destination: VideoCaptureView()) {
                    Text("Go to Camera")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
            }
            .padding()
            .navigationTitle("BoxMotion Tracker")
        }
    }
}




