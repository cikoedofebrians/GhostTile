//
//  StartView.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 14/06/25.
//


//
//  StartGameView.swift
//  GhostTile
//
//  Created by Johansen Marlee on 11/06/25.
//

import SwiftUI
import SpriteKit

struct StartGameView: View {
    @StateObject var cameraManager: CameraManager = CameraManager()
    private var startScene = StartScene()
    @State private var shouldStartGame = false
    
    
    var body: some View {
        if shouldStartGame {
            TilesView(cameraManager: cameraManager)
        } else {
            SpriteView(scene: startScene, options: [.allowsTransparency])
                .ignoresSafeArea()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    startScene.onCountDownComplete = {
                        DispatchQueue.main.async {
                            shouldStartGame = true
                        }
                    }
                }
                .onChange(of: cameraManager.faceNods) { oldValue, newValue in
                    if oldValue.count != newValue.count {
                        startScene.updateCharacterAnimation(for: newValue.count)
                    }
                    if newValue.count == 2 {
                        let playerOneNodded = newValue[0]
                        let playerTwoNodded = newValue[1]
                        if  playerOneNodded {
                            startScene.StartPlayerOneReady()
                        }
                        if playerTwoNodded {
                            startScene.StartPlayerTwoReady()
                        }
                    }
                }
//                .onChange(of: cameraManager.playerOneNodded) { _, newValue in
//                    if newValue {
//                        startScene.StartPlayerOneReady()
//                    }
//                }
//                .onChange(of: cameraManager.playerTwoNodded) { _, newValue in
//                    if newValue {
//                        startScene.StartPlayerTwoReady()
//                    }
//                }
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
