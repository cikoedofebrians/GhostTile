//
//  Untitled.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 14/06/25.
//

import SpriteKit
import SwiftUI
import AVFoundation

class StartScene: SKScene {
    
    private var backgroundMusicPlayer: AVAudioPlayer?
    
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
    private var hasPlayedPlayerOneDetectedOnce = false
    private var hasPlayedPlayerTwoDetectedOnce = false
    
    private var statusTextNode: SKSpriteNode?
    
    
    private var blackOpacityBackground: SKSpriteNode = {
        let node = SKSpriteNode(color: .black, size: .zero)
        node.zPosition = -2
        node.anchorPoint = CGPoint(x: 0, y: 0)
        node.alpha = 0.5
        node.position = CGPoint(x: 0, y: 0)
        return node
    }()
    
    
    let background: SKSpriteNode = {
        let background = SKSpriteNode()
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.zPosition = -100
        let textures = (1...8).map { SKTexture(imageNamed: "background_\($0)") }
        let animation = SKAction.animate(with: textures, timePerFrame: 0.2)
        background.run(SKAction.repeatForever(animation))
        return background
    }()
    
    override init() {
        super.init(size: .zero)
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
        setupBackground()
        
        playBackgroundMusic()
        setupStatusText()
    }
    
   
    private func setupStatusText() {
        
        let statusNode = SKSpriteNode(imageNamed: "notready")
        statusNode.zPosition = 2
        statusNode.setScale(1.0)
        
        
        if let orderNode = self.nodeOrderNode {
            statusNode.position = CGPoint(x: size.width / 2, y: orderNode.position.y + orderNode.size.height / 2 - 200)
        } else {
            statusNode.position = CGPoint(x: size.width / 2, y: size.height / 2 - 200)
        }
        
        addChild(statusNode)
        self.statusTextNode = statusNode
    }
    
    
    private func updateStatusText(for playerCount: Int) {
        guard let statusNode = statusTextNode else { return }
        
        let newTexture: SKTexture
        
        switch playerCount {
        case 0:
            newTexture = SKTexture(imageNamed: "notready")
        case 1:
            newTexture = SKTexture(imageNamed: "oneplayer")
        case 2:
            newTexture = SKTexture(imageNamed: "bothready")
        default:
            return
        }
        
        if statusNode.texture?.hash != newTexture.hash {
            statusNode.texture = newTexture
        }
    }
    
    
    func playBackgroundMusic() {
            
            guard let url = Bundle.main.url(forResource: "start-song", withExtension: "mp3") else {
                print("Error: File audio tidak ditemukan.")
                return
            }
            
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
            } catch {
                print("Error: Tidak bisa memutar file audio - \(error.localizedDescription)")
            }
        }
    
    func setupBackground() {
        background.size = CGSize(width: size.width, height: size.height)
        background.position = CGPoint(x: 0, y: 0)
        blackOpacityBackground.size = CGSize(width: size.width, height: size.height)
        blackOpacityBackground.position = CGPoint(x: 0, y: 0)
        addChild(background)
        addChild(blackOpacityBackground)
    }
    
    
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
            if playerCount == 0 {
                self.StartIdleAnimation()
                hasPlayedPlayerOneDetectedOnce = false
                hasPlayedPlayerTwoDetectedOnce = false
            } else if playerCount == 1 {
                self.StartPlayerOneDetected()
                hasPlayedPlayerTwoDetectedOnce = false
            } else if playerCount == 2 {
                self.StartPlayerTwoDetected()
            }
        }
    
    private func setupTitle() {
        let title = SKSpriteNode(imageNamed: "GhostTiles")
        title.zPosition = 1000
        title.setScale(1)
        title.position = CGPoint(x: size.width / 2, y: size.height - 200)
        addChild(title)
        self.titleNode = title
    }
    
    private func setupMouths() {
        let y = size.height - size.height / 3 - 280
        
        let mouthNodeFront = SKSpriteNode(imageNamed: "1_bottom_mouth")
        let mouthNodeFrontTextures = (1...8).map { SKTexture(imageNamed: "\($0)_bottom_mouth") }
        let mouthNodeFrontAnimation = SKAction.animate(with: mouthNodeFrontTextures, timePerFrame: 0.2)
        mouthNodeFront.run(SKAction.repeatForever(mouthNodeFrontAnimation))
        mouthNodeFront.zPosition = -20
        mouthNodeFront.setScale(0.6)
        mouthNodeFront.position = CGPoint(x: size.width / 2, y: y)
        addChild(mouthNodeFront)
        
        
        let mouthNodeBack = SKSpriteNode(imageNamed: "1_mouth_top")
        let mouthNodeBackTextures = (1...8).map { SKTexture(imageNamed: "\($0)_mouth_top") }
        let mouthNodeBackAnimation  = SKAction.animate(with: mouthNodeBackTextures, timePerFrame: 0.2)
        mouthNodeBack.run(SKAction.repeatForever(mouthNodeBackAnimation))
        mouthNodeBack.zPosition = -5
        mouthNodeBack.setScale(0.6)
        
        mouthNodeBack.position = CGPoint(x: size.width / 2, y: y)
        
        addChild(mouthNodeBack)
        
    }
    
    
    private func startCountdownThenGame(){
        titleNode?.removeFromParent()
        nodeOrderNode?.removeFromParent()
        
        statusTextNode?.removeFromParent()
        
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
            line.zPosition = -5
            lanes.append(line)
            addChild(line)
        }
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
        character.run(SKAction.repeatForever(sequence), withKey: "startAnimation")
    }
    
    private func playPlayerOneDetectedIntroThenLoop() {
        guard let character = character else { return }
        character.removeAllActions()
        
        let introFrames = (5...9).map { SKTexture(imageNamed: "Start-\($0)") }
        let loopFrames = (6...9).map { SKTexture(imageNamed: "Start-\($0)") }

        let introAction = SKAction.animate(with: introFrames, timePerFrame: 0.1)
        let loopAction = SKAction.animate(with: loopFrames, timePerFrame: 0.1)
        let loopForever = SKAction.repeatForever(loopAction)

        let sequence = SKAction.sequence([introAction, loopForever])
        character.run(sequence, withKey: "startAnimation")
    }
    
    private func playPlayerTwoDetectedIntroThenLoop() {
        guard let character = character else { return }
        character.removeAllActions()
        
        let introFrames = (13...17).map { SKTexture(imageNamed: "Start-\($0)") }
        let loopFrames = (15...17).map { SKTexture(imageNamed: "Start-\($0)") }

        let introAction = SKAction.animate(with: introFrames, timePerFrame: 0.1)
        let loopAction = SKAction.animate(with: loopFrames, timePerFrame: 0.1)
        let loopForever = SKAction.repeatForever(loopAction)

        let sequence = SKAction.sequence([introAction, loopForever])
        character.run(sequence, withKey: "startAnimation")
    }
    
    private func playPlayerOneReadyIntroThenLoop() {
        guard let character = character else { return }
        character.removeAllActions()
        
        let introFrames = (21...24).map { SKTexture(imageNamed: "Start-\($0)") }
        let loopFrames = (22...24).map { SKTexture(imageNamed: "Start-\($0)") }

        let introAction = SKAction.animate(with: introFrames, timePerFrame: 0.1)
        let loopAction = SKAction.animate(with: loopFrames, timePerFrame: 0.1)
        let loopForever = SKAction.repeatForever(loopAction)

        let sequence = SKAction.sequence([introAction, loopForever])
        character.run(sequence, withKey: "startAnimation")
    }
    
    private func playPlayerTwoReadyIntroThenLoop() {
        guard let character = character else { return }
        character.removeAllActions()
        
        let introFrames = (25...28).map { SKTexture(imageNamed: "Start-\($0)") }
        let loopFrames = (26...28).map { SKTexture(imageNamed: "Start-\($0)") }

        let introAction = SKAction.animate(with: introFrames, timePerFrame: 0.1)
        let loopAction = SKAction.animate(with: loopFrames, timePerFrame: 0.1)
        let loopForever = SKAction.repeatForever(loopAction)

        let sequence = SKAction.sequence([introAction, loopForever])
        character.run(sequence, withKey: "startAnimation")
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
            playPlayerOneDetectedIntroThenLoop()
    }
    
    func StartPlayerOneReady() {
        playPlayerOneReadyIntroThenLoop()
        isPlayerOneReady = true
        checkIfBothPlayersReady()
    }
    
    func StartPlayerTwoDetected() {
        if !hasPlayedPlayerTwoDetectedOnce {
            playPlayerTwoDetectedIntroThenLoop()
            hasPlayedPlayerTwoDetectedOnce = true
        }
    }
    
    func StartPlayerTwoReady() {
        playPlayerTwoReadyIntroThenLoop()
        isPlayerTwoReady = true
        checkIfBothPlayersReady()
    }
    
    func idleAnimation() {
        playAnimation(named: "idle")
    }
    
}

