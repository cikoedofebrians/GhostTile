//
//  TheTilesView.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 11/06/25.
//

import SwiftUI
import SpriteKit


struct TilesView: View {
    @ObservedObject var cameraManager: CameraManager
    
    var body: some View {
        SpriteView(scene:  Tiles(cameraManager: cameraManager))
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TilesView(cameraManager: CameraManager())
}
