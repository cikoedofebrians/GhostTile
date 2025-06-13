//
//  GhostTileApp.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 04/06/25.
//

import SwiftUI

@main
struct GhostTileApp: App {
    @StateObject private var cameraManager = CameraManager()
    var body: some Scene {
        WindowGroup {
            StartGameView(cameraManager: cameraManager)
//            TheTilesView(cameraManager: cameraManager)
        }
    }
}
