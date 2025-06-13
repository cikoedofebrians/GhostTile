//
//  StartGameView.swift
//  GhostTile
//
//  Created by Johansen Marlee on 11/06/25.
//

import SwiftUI
import SpriteKit

struct StartGameView: View {
    @ObservedObject var cameraManager: CameraManager
    //    @State private var startScene = StartScene(size: CGSize(width: 800, height: 600))
    //    @State private var startScene: StartScene?
    @State private var startScene = StartScene(size: UIScreen.main.bounds.size)
    @State private var shouldStartGame = false
    
    
    var body: some View {
        Group {
            if shouldStartGame {
                TheTilesView(cameraManager: cameraManager)
            } else {
                SpriteView(scene: startScene, options: [.allowsTransparency])
                    .ignoresSafeArea()
                    .onAppear {
                        startScene.onCountDownComplete = {
                            DispatchQueue.main.async {
                                shouldStartGame = true
                            }
                        }
                    }
                    .onChange(of: cameraManager.playerCount) { _, newCount in
                        startScene.updateCharacterAnimation(for: newCount)
                    }
                    .onChange(of: cameraManager.playerOneNodded) { _, newValue in
                        if newValue {
                            startScene.StartPlayerOneReady()
                        }
                    }
                    .onChange(of: cameraManager.playerTwoNodded) { _, newValue in
                        if newValue {
                            startScene.StartPlayerTwoReady()
                        }
                    }
            }
        }
    }
}





//        SpriteView(scene: startScene)
//            .ignoresSafeArea()
//            .onChange(of: cameraManager.playerCount) {_, newCount in
//                startScene.updateCharacterAnimation(for: newCount)
//            }
//            .onChange(of: cameraManager.playerOneNodded) { _, newValue in
//                if newValue {
//                    startScene.StartPlayerOneReady()
//                }
//            }
//            .onChange(of: cameraManager.playerTwoNodded) { _, newValue in
//                if newValue {
//                    startScene.StartPlayerTwoReady()
//                }
//            }
