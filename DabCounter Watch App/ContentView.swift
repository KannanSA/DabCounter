//
//  ContentView.swift
//  DabCounter Watch App
//
//  Created by Kannan Sekar Annu Radha on 17/09/2024.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @ObservedObject var motionManager = MotionManager()
    @State private var showEmoji: Bool = false // State to control emoji visibility
    
    var body: some View {
        VStack {
            Text("Dab Counter")
                .font(.headline)
            
            Text("\(motionManager.dabCount)")
                .font(.system(size: 50))
                .fontWeight(.bold)
                .padding()

            // Display the emoji with animation
            if showEmoji {
                Text("😂")
                    .font(.system(size: 50)) // Set the emoji size
                    .transition(.scale)
                    .padding()
            }
            
            Button(action: {
                motionManager.dabCount = 0
            }) {
                Text("Reset")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .onReceive(motionManager.$dabCount) { _ in
            // Show the emoji for a short period when a new dab is counted
            withAnimation {
                showEmoji = true
            }
            
            // Hide the emoji after 1 second
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation {
                    showEmoji = false
                }
            }
        }
        .onDisappear {
            motionManager.stopMotionUpdates()
        }
    }
}
