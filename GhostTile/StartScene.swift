//
//  StartScene.swift
//  GhostTile
//
//  Created by Johansen Marlee on 11/06/25.
//

import SpriteKit
import SwiftUI

class StartScene: SKScene {
    var onCountDownComplete: (() ->Void)?
    let numberOfLanes = 4
    let baseHeight: CGFloat = 100
    let laneWidth: CGFloat = 160.0
    var lanes: [SKShapeNode] = []
    var box: SKSpriteNode? = nil
    let topScale: CGFloat = 0.3
    let bottomScale: CGFloat = 1.5
    var currentLaneIndex: Int = 0
    var characterLaneIndex: Int = 0
    var currentBoxY: CGFloat = 0
    var character: SKSpriteNode? = nil
    var gameStarted =  false
    
    var titleNode: SKSpriteNode?
    var nodeOrderNode: SKSpriteNode?
    
    private var isPlayerOneReady = false
    private var isPlayerTwoReady = false
    
    
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView){
        setupPerspectiveLines()
        setupCharacter()
        setupTitle()
        setupMouths()
        setupNodeOrder()
    }
    
    //bukan page image tapi pake animation
    
    private func setupCharacter() {
        let char = SKSpriteNode()
        
        char.size = CGSize(width: 200, height: 200)
        char.zPosition = 1
        char.anchorPoint = CGPoint(x: 0, y: 0)
        char.position = CGPoint(x: (size.width - char.size.width) / 2 , y: 0)
        character = char
        StartIdleAnimation()
        addChild(char)
    }
    
    func updateCharacterAnimation(for playerCount: Int) {
        guard !gameStarted else { return }
        
        print("DEBUG: Detected \(playerCount) player(s)")
        
        if playerCount == 0 {
            self.StartIdleAnimation()
        } else if playerCount == 1 {
            self.StartPlayerOneDetected()
        } else if playerCount == 2 {
            self.StartPlayerTwoDetected()
        }
    }
    
    
    private func setupTitle() {
        let title = SKSpriteNode(imageNamed: "GhostTiles")
        title.zPosition = 2
        title.setScale(1)
        title.position = CGPoint(x: size.width / 2, y: size.height - 200)
        addChild(title)
        self.titleNode = title
    }
    
    
    private func setupMouths() {
        let mouthNode = SKSpriteNode(imageNamed: "Mouth")
        mouthNode.zPosition = 1
        mouthNode.setScale(0.7)
        mouthNode.alpha = 0.5
        
        mouthNode.position = CGPoint(x: size.width / 2, y: size.height / 3 - 100)
        addChild(mouthNode)
    }
    
    private func setupNodeOrder() {
        let nodeOrder = SKSpriteNode(imageNamed: "StartNodeOrder")
        nodeOrder.zPosition = 1
        nodeOrder.setScale(1.5)
        nodeOrder.position = CGPoint(x: size.width / 2, y: size.height / 2 - 200)
        addChild(nodeOrder)
        self.nodeOrderNode = nodeOrder
    }
    
    private func startCountdownThenGame(){
        titleNode?.removeFromParent()
        nodeOrderNode?.removeFromParent()
        
        let countdownNumbers = ["Countdown-3", "Countdown-2", "Countdown-1"]
        var countdownSprites: [SKSpriteNode] = []
        
        for i in 0..<countdownNumbers.count {
            let sprite = SKSpriteNode(imageNamed: countdownNumbers[i])
            sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
            sprite.zPosition = 5
            sprite.alpha = 0 // Start invisible
            countdownSprites.append(sprite)
            addChild(sprite)
        }
        
        for (index, sprite) in countdownSprites.enumerated() {
            let delay = Double(index)
            let showAction = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.wait(forDuration: 0.8),
                SKAction.fadeOut(withDuration: 0.2)
            ])
            sprite.run(showAction)
        }
        
        let totalDuration = Double(countdownNumbers.count) * 1.0
        run(SKAction.sequence([
            SKAction.wait(forDuration: totalDuration),
            SKAction.run { [weak self] in
                self?.onCountDownComplete?()
    //                if let view = self.view {
//                    let mainGame = TheTiles()
//                    mainGame.scaleMode = .resizeFill
//                    view.presentScene(mainGame, transition: .fade(withDuration: 1.0))
//                }
            }
        ]))
        
    }
    
    
    
    
    
    
    
    
    private func setupPerspectiveLines() {
        for i in 0...numberOfLanes {
            let line = SKShapeNode()
            let path = CGMutablePath()
            let baseX = CGFloat(i) * laneWidth - CGFloat(numberOfLanes) * laneWidth / 2
            let nearX = baseX * bottomScale
            let farX = baseX * topScale
            path.move(to: CGPoint(x: size.width / 2 + nearX, y: 0))
            path.addLine(to: CGPoint(x: size.width / 2 + farX, y: size.height - size.height/3))
            line.path = path
            line.strokeColor = .white
            line.lineWidth = 2
            line.alpha = 0.1
            line.name = "laneLine"
            lanes.append(line)
            addChild(line)
        }
        currentBoxY = size.height - size.height / 3
        let horizonLine = SKShapeNode(rect: CGRect(x: 0, y: size.height - size.height/3, width: size.width, height: 2))
        horizonLine.fillColor = .white
        horizonLine.alpha = 0.0
        horizonLine.name = "horizonLine"
        addChild(horizonLine)
    }
    
    
    private func startGameIfBothReady() {
        guard !gameStarted else { return }
        gameStarted = true
        startCountdownThenGame()
    }
    
    private func playAnimation(named animationName: String) {
        guard let character = character else { return }
        
        character.removeAllActions()
        
        let frameRange: [Int]
        
        switch animationName.lowercased() {
        case "startidle":
            frameRange = Array(1...4)
        case "startplayeronedetected":
            frameRange = Array(5...12)
        case "startplayertwodetected":
            frameRange = Array(13...20)
        case "startplayeroneready":
            frameRange = Array(21...24)
        case "startplayertwoready":
            frameRange = Array(25...28)
        default:
            print("Unknown animation name: \(animationName)")
            return
        }
        
        let textures = frameRange.map { SKTexture(imageNamed: "Start-\($0)") }
        
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        let sequence = SKAction.sequence([animation, animation.reversed()])
        character.run(SKAction.repeatForever(sequence))
    }
    
    private func checkIfBothPlayersReady(){
        if(isPlayerOneReady && isPlayerTwoReady){
            startGameIfBothReady()
        }
    }
    
    
    func StartIdleAnimation() {
        playAnimation(named: "StartIdle")
    }
    
    func StartPlayerOneDetected() {
        playAnimation(named: "StartPlayerOneDetected")
    }
    
    
    func StartPlayerOneReady() {
        playAnimation(named: "StartPlayerOneReady")
        isPlayerOneReady = true
        checkIfBothPlayersReady()
    }
    
    func StartPlayerTwoDetected() {
        playAnimation(named: "StartPlayerTwoDetected")
    }
    
    func StartPlayerTwoReady() {
        playAnimation(named: "StartPlayerTwoReady")
        isPlayerTwoReady = true
        checkIfBothPlayersReady()
    }
    func idleAnimation() {
        playAnimation(named: "idle")
    }
    
    
    
}


