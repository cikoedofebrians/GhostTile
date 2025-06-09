//
//  ContentView.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 04/06/25.
//

import SwiftUI

enum RollSide {
    case left
    case right
    case straight
}
struct ContentView: View {
    @State var ballIndex: Int = 0
    @State var tiltCounts: [Double] = []
    @State var rollSide: RollSide = .straight
    
    var body: some View {
        ZStack {
            CameraView(tiltCounts: $tiltCounts, rollSide: $rollSide, ballIndex: $ballIndex)
                .ignoresSafeArea()
            if tiltCounts.count < 2 {
                Text("Please have 2 faces in the frame")
                    .font(.title)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .transition(.blurReplace())
                    
            } else if tiltCounts.count > 2 {
                Text("Please have only 2 faces in the frame")
                    .font(.title)
                    .foregroundStyle(.white)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.5))
                    .transition(.blurReplace())
            
             } else {
                
                VStack {
                    HStack {
                        Text("Total Faces: \(tiltCounts.count)")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background {
                                Capsule()
                                    .foregroundStyle(Color.red)
                            }
                        Spacer()
                        Text("\(rollSide == .left ? "Left" : rollSide == .right ? "Right" : "Straight")")
                            .font(.title)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background {
                                Capsule()
                                    .foregroundStyle(Color.blue)
                            }
                    }
                    .padding(.top, 24)
            
                    Spacer()
                    HStack {
                        ForEach(0..<4) { index in
                            Circle()
                                .fill(ballIndex == index ? Color.red : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 50)
                        }
                    }
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 100)
                            .fill(.white)
                    }
                }
                .transition(.blurReplace())
                .foregroundStyle(.white)
                
            }
            
        }
    }
}

//#Preview {
//    ContentView()
//}
