//
//  TheTilesView.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 11/06/25.
//

import SwiftUI
import SpriteKit


struct TilesView: View {
    @Binding var shouldStartGame: Bool
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        SpriteView(scene: Tiles(cameraManager: cameraManager, shouldStartGame: $shouldStartGame), options: [.allowsTransparency])
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TilesView(shouldStartGame: .constant(true), cameraManager: CameraManager())
}
