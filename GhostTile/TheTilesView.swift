//
//  TheTilesView.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 11/06/25.
//

import SwiftUI
import SpriteKit


struct TheTilesView: View {
    @ObservedObject var cameraManager: CameraManager
    @State private var gameScene: TheTiles = TheTiles()
    
    var body: some View {
        SpriteView(scene: gameScene)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Perspective Runner")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: cameraManager.lastRollSide) { oldValue, newValue in
                if oldValue != newValue {
                    switch newValue {
                    case .left:
                        gameScene.moveLeft()
                    case .right:
                        gameScene.moveRight()
                    default:
                        break
                    }
                }
            }
            .onChange(of: cameraManager.faceRollSide) { oldValue, newValue in
                guard newValue.count == 2,
                      let first = newValue.first,
                      let second = newValue.last else { return }
                print("DEBUG: Triggering ANIMATIONNNNNNNN")

                if (first == .none && second == .right) || (first == .right && second == .none) {
                    print("DEBUG: Triggering right animation")
                    gameScene.rightAnimation()
                } else if (first == .none && second == .left) || (first == .left && second == .none) {
                    print("DEBUG: Triggering left animation")
                    gameScene.leftAnimation()
                } else if first == .right && second == .left {
                    print("DEBUG: Triggering crash animation")
                    gameScene.crashAnimation()
                } else if first == .left && second == .right {
                    print("DEBUG: Triggering inverse crash animation")
                    gameScene.crashInverseAnimation()
                } else if first == .none && second == .none {
                    print("DEBUG: Triggering idle animation")
                    gameScene.idleAnimation()
                }
            }

    }
   
}


#Preview {
    TheTilesView(cameraManager: CameraManager())
}
