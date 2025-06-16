//
//  GameProtocol.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 13/06/25.
//

protocol GameDelegate {
    func moveLeft()
    func moveRight()
    func blinkDetected()
    func rightAnimation()
    func leftAnimation()
    func crashAnimation()
    func crashInverseAnimation()
    func idleAnimation()
    
    // gw tambahin ini
    func nodDetected()
}
