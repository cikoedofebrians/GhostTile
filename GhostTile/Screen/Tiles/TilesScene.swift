//
//  TheTiles.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 09/06/25.
//

import SpriteKit
import SwiftUI
import AVKit


class Tiles: SKScene {
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
    var initialTouch: CGPoint?
    var scoreLabel: SKLabelNode?
    var scoreValueLabel: SKLabelNode?
    var scoreValueBackground: SKShapeNode?
    var scoreValueContainer: SKNode?
    var timer: Timer?
    var totalTime: Double = 0
    var score: Int = 0
    private var mouthFront: SKSpriteNode?
    private var mouthBack: SKSpriteNode?
    private var mouthStage: Int = 0
    var currentLaneSpan: Int = 1
    var boxes: [SKSpriteNode] = []
    var activeBoxes: [(node: SKSpriteNode, laneIndex: Int, y: CGFloat)] = []
    var boxSpawnCooldown: TimeInterval = 0
    var boxSpawnRate: TimeInterval = 3.0
    var spawnAcceleration: TimeInterval = 0.0
    let minBoxSpawnRate: TimeInterval = 1.5
    var lastSpawnedLanes: [Int] = []
    var totalElapsedTime: TimeInterval = 0
    var lastAllLaneSpawnTime: TimeInterval = 0
    var currentLane: Int = 0
    var isInCollisionCooldown = false
    var lastCollisionTime: TimeInterval = 0
    let collisionThreshold: CGFloat = 100
    var scoreAcceleration: Double = 0.1
    var currentScore: Double = 0.0
    var lastScoreUpdate: TimeInterval = 0
    var scoreUpdateInterval: TimeInterval = 1
    var scoreIncrement: Double = 1.0
    var isWallSpawned: Bool = false
    var wallY: CGFloat = 0.0
    var crashOverlay : SKSpriteNode?
    var bulletTimer: Timer?
    let cameraManager: CameraManager
    var hasBlinked: Bool = false

    // Var lama bikin
    var collisionCount: Int = 0
    let maxCollisions: Int = 3
    var isGameOver: Bool = false
    var gameOverNode: SKNode?
    let randomJumpscareImages: [String] = ["jumpscare", "kucing"]
    
    var playerOneNodded: Bool = false
    var playerTwoNodded: Bool = false
    var restartLabel: SKLabelNode?

    
    let specialJumpscareImage: String = "mouthClosing_dummy"

    let blink: SKSpriteNode = {
        let blinkNode = SKSpriteNode()
        blinkNode.color = .redBlink
        blinkNode.anchorPoint = CGPoint(x: 0, y: 0)
        blinkNode.alpha = 0
        blinkNode.zPosition = 1000
        return blinkNode
    }()
          
    func setupBackgroundMusic() {
//      if let musicURL = Bundle.main.url(forResource: "backsound", withExtension: "mp3") {
//          let backgroundMusic = SKAudioNode(url: musicURL)
//          backgroundMusic.autoplayLooped = true
//          addChild(backgroundMusic)
//      }
    }
    
    let background: SKSpriteNode = {
        let background = SKSpriteNode()
        background.anchorPoint = CGPoint(x: 0, y: 0)
        background.zPosition = -100
        let textures = (1...8).map { SKTexture(imageNamed: "background_\($0)") }
        let animation = SKAction.animate(with: textures, timePerFrame: 0.2)
        background.run(SKAction.repeatForever(animation))
        return background
    }()
    
    let wall: SKSpriteNode = {
        let wall =  SKSpriteNode(color: .white, size: CGSize(width: 0, height: 0))
        wall.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        let textures = (1...6).map { SKTexture(imageNamed: "wall_\($0)") }
        let animation = SKAction.animate(with: textures, timePerFrame: 0.2)
        let fullAnimation = SKAction.sequence([animation, animation.reversed()])
        wall.run(SKAction.repeatForever(fullAnimation))
        return wall
    }()
    
    
    init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
        super.init(size: .zero)
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.scaleMode = .resizeFill
        self.backgroundColor = .black
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupAcceleration() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // ini buat pastiin timer countnya berhenti pas game over
            if self.isGameOver {
                self.timer?.invalidate()
                return
            }
            self.scoreAcceleration += 0.01
        }
    }
    
    func setupBackground() {
        background.size = CGSize(width: size.width, height: size.height)
        addChild(background)
    }
    
    private func adjustTimer(currentTime: TimeInterval) {
        if currentTime - lastScoreUpdate >= scoreUpdateInterval - scoreAcceleration {
            currentScore += 1
            score = Int(currentScore)
            lastScoreUpdate = currentTime
            scoreUpdateInterval = max(0.04, scoreUpdateInterval)
            
            if let scoreValueLabel = self.scoreValueLabel, let scoreValueBackground = self.scoreValueBackground, let scoreLabel = scoreLabel, let scoreValueContainer = scoreValueContainer {
                scoreValueLabel.text = "\(score)"
                
                let backgroundSize = CGSize(width: scoreValueLabel.frame.size.width + 48, height: scoreValueLabel.frame.size.height + 24)
                let centeredRect = CGRect(x: -backgroundSize.width/2, y: -backgroundSize.height/2, width: backgroundSize.width, height: backgroundSize.height)
                scoreValueBackground.path = CGPath(roundedRect: centeredRect, cornerWidth: 8, cornerHeight: 8, transform: nil)
                scoreValueContainer.position = CGPoint(x: size.width - backgroundSize.width / 2 - 32, y: size.height - backgroundSize.height / 2 - scoreLabel.frame.size.height - 32)
            }
        }
    }
    
    private func setupScore() {
        let scoreTitleLabel = SKLabelNode(text: "Score")
        scoreTitleLabel.fontSize = 36
        scoreTitleLabel.fontName = "Arial-SemiBoldMT"
        scoreLabel = scoreTitleLabel
        let scoreValLabel = SKLabelNode(text: "\(score)")
        
        scoreValLabel.fontSize = 48
        scoreValLabel.fontColor = .white
        scoreValLabel.fontName = "Arial-BoldMT"
        
        scoreValueLabel = scoreValLabel
        
        scoreValLabel.verticalAlignmentMode = .center
        scoreValLabel.horizontalAlignmentMode = .center
        let backgroundSize = CGSize(width: scoreValLabel.frame.size.width + 48, height: scoreValLabel.frame.size.height + 24)
        let background = SKShapeNode(rectOf: backgroundSize, cornerRadius: 8)
        scoreValueBackground = background
        
        background.fillColor = .red
        background.strokeColor = .clear
        
        let scoreValContainer = SKNode()
        scoreValueContainer = scoreValContainer
        scoreValContainer.addChild(background)
        scoreValContainer.addChild(scoreValLabel)
        
        
        addChild(scoreTitleLabel)
        addChild(scoreValContainer)
        
        scoreTitleLabel.zPosition = 10
        scoreValContainer.zPosition = 10
        scoreTitleLabel.position = CGPoint(x: size.width - scoreTitleLabel.frame.size.width / 2 - 32,  y: size.height - scoreTitleLabel.frame.size.height / 2 - 32)
        scoreValContainer.position = CGPoint(x: size.width - backgroundSize.width / 2 - 32, y: size.height - backgroundSize.height / 2 - scoreTitleLabel.frame.size.height - 32)
    }
    
    func laneEdgeX(laneIndex: Int, y: CGFloat) -> CGFloat {
        let startY: CGFloat = 0
        let endY: CGFloat = size.height - size.height/3
        
        let baseX = CGFloat(laneIndex) * laneWidth - CGFloat(numberOfLanes) * laneWidth / 2
        let startX = size.width / 2 + baseX * bottomScale
        let endX = size.width / 2 + baseX * topScale
        
        let t = (y - startY) / (endY - startY)
        return startX + (endX - startX) * t
    }
    
    
    override func didMove(to view: SKView) {
        cameraManager.delegate = self
        setupGame()
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(view.handleMouthTap(_:)))
        view.addGestureRecognizer(tap)
    }

    
    func setupGame() {
        self.removeAllChildren()
        self.removeAllActions()
        
        // Reset state
        isGameOver = false
        collisionCount = 0
        score = 0
        currentScore = 0
        totalElapsedTime = 0
        activeBoxes.removeAll()
        
        playerOneNodded = false
        playerTwoNodded = false
        
        setupBackground()
        setupPerspectiveLines()
        setupCharacter()
        setupMouths()
        setupScore()
        setupAcceleration()
        setupCrashOverlay()
        setupBackgroundMusic()
    }
    
    func shootBullet() {
        
    }
    
    func showBlinkEffect() {
        if !hasBlinked {
            DispatchQueue.main.async {
                self.hasBlinked = true
            }
            blink.size = CGSize(width: size.width, height: size.height)
            let blinkAction = SKAction.sequence([
                SKAction.fadeAlpha(to: 1.0, duration: 0.1),
                SKAction.fadeAlpha(to: 0.0, duration: 0.1),
            ])
            let repeatedBlinkAction = SKAction.repeat(blinkAction, count: 4)
            let fullAction = SKAction.sequence([
                repeatedBlinkAction,
                SKAction.removeFromParent()
            ])
            blink.run(fullAction)
            addChild(blink)
            
        }
    }
    
    
    func calculateScale(forY y: CGFloat) -> CGFloat {
        let y1: CGFloat = size.height - size.height / 3
        let s1: CGFloat = topScale
        
        let y2: CGFloat = 0.0
        let s2: CGFloat = bottomScale
        
        let slope = (s2 - s1) / (y2 - y1)
        
        let intercept = s2 - slope * y2
        let scale = slope * y + intercept
        
        return scale
    }

    override func update(_ currentTime: TimeInterval) {
        // stop up kl gameover
        guard !isGameOver else { return }

        if lanes.count > 1 {
            
            adjustTimer(currentTime: currentTime)
            boxSpawnCooldown -= 1/60
            totalElapsedTime += 1.0 / 60.0
            
            if isWallSpawned && activeBoxes.isEmpty {
                showBlinkEffect()
                if wallY == size.height - size.height / 3 {
                    let action = SKAction.fadeAlpha(to: 1.0, duration: 1)
                    wall.run(action)
                }
                let scale = calculateScale(forY: wallY - 6)
                wallY -= 6 * scale
                let widthX1 = laneEdgeX(laneIndex: 0, y: wallY)
                let widthX2 = laneEdgeX(laneIndex: 4, y: wallY)
                let width = abs(widthX2 - widthX1)
                wall.size = CGSize(width: width, height: 160 * scale)
                wall.position = CGPoint(x: widthX1 + width / 2, y: wallY)
                
                if wallY < -wall.size.height {
                    wall.removeFromParent()
                    hasBlinked = false
                    isWallSpawned = false
                }
            }
            if isWallSpawned && !activeBoxes.isEmpty || !isWallSpawned {
                for (index, boxData) in activeBoxes.enumerated().reversed() {
                    let (box, laneIndex, y) = boxData
                    
                    let scale = calculateScale(forY: y)
                    let widthX1 = laneEdgeX(laneIndex: laneIndex, y: y)
                    let widthX2 = laneEdgeX(laneIndex: laneIndex + 1, y: y)
                    let width = abs(widthX2 - widthX1)
                    
                    box.size = CGSize(width: width, height: baseHeight * scale)
                    box.position = CGPoint(x: widthX1 + width / 2, y: y)
                    
                    var newY = y - (6 * scale)
                    activeBoxes[index].y = newY
                    
                    if newY < -box.size.height {
                        box.removeFromParent()
                        activeBoxes.remove(at: index)
                    }
                }
                
                let y = size.height - size.height / 3
                let scale = calculateScale(forY: y)
                
                if boxSpawnCooldown <= 0 {
                    var selectedLanes: [Int] = []
                    
                    if totalElapsedTime - lastAllLaneSpawnTime >= 30 && !isWallSpawned {
                        selectedLanes = [0, 1, 2, 3]
                        lastAllLaneSpawnTime = totalElapsedTime
                        isWallSpawned = true
                        wallY = y
                        let widthX1 = laneEdgeX(laneIndex: 0, y: wallY)
                        let widthX2 = laneEdgeX(laneIndex: 4, y: wallY)
                        let width = abs(widthX2 - widthX1)
                        let sizeBox = CGSize(width: width, height: 160 * scale)
                        wall.alpha = 0.0
                        wall.size = sizeBox
                        wall.position = CGPoint(x: widthX1 + width / 2, y: y)
                        addChild(wall)
                        
                    } else  if !isWallSpawned {
                        let numberOfLanesToCover = Int.random(in: 1...3)
                        let allCombinations: [[Int]] = [[0], [1], [2], [3], [0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3], [0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]
                        
                        let minBoxCount: Int
                        let maxBoxCount: Int
                        
                        switch totalElapsedTime {
                        case 0..<20: minBoxCount = 1; maxBoxCount = 2
                        case 20..<40: minBoxCount = 1; maxBoxCount = 3
                        case 40..<60: minBoxCount = 2; maxBoxCount = 3
                        default: minBoxCount = 3; maxBoxCount = 3
                        }
                        
                        let possibleCombinations = allCombinations.filter { $0.count >= minBoxCount && $0.count <= maxBoxCount }
                        let candidates = possibleCombinations.filter { $0.count == numberOfLanesToCover }
                        let validCandidates = candidates.filter { !Set($0).isSubset(of: Set(lastSpawnedLanes)) }
                        guard let chosen = (validCandidates.isEmpty ? candidates : validCandidates).randomElement() else { return }
                        selectedLanes = chosen
                        
                        if !selectedLanes.contains(currentLane) {
                            selectedLanes[Int.random(in: 0..<selectedLanes.count)] = currentLane
                        }
                        
                        for laneIndex in selectedLanes {
                            let widthX1 = laneEdgeX(laneIndex: laneIndex, y: y)
                            let widthX2 = laneEdgeX(laneIndex: laneIndex + 1, y: y)
                            let width = abs(widthX2 - widthX1)
                            let sizeBox = CGSize(width: width, height: baseHeight * scale)
                            
                            let box = SKSpriteNode(color: .white, size: sizeBox)
                            box.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                            box.alpha = 0
                            box.position = CGPoint(x: widthX1 + width / 2, y: y)
                            
                            let textures = (1...3).map { SKTexture(imageNamed: "obstacle_\($0)") }
                            let animation = SKAction.animate(with: textures, timePerFrame: 0.2)
                            let fullAnimation = SKAction.sequence([animation, animation.reversed()])
                            box.run(SKAction.repeatForever(fullAnimation))
                            box.run(SKAction.fadeAlpha(to: 1, duration: 1))
                            
                            addChild(box)
                            activeBoxes.append((node: box, laneIndex: laneIndex, y: y))
                        }
                    }
                    
                    lastSpawnedLanes = selectedLanes
                    spawnAcceleration += 0.01
                    let newSpawnRate = max(minBoxSpawnRate, boxSpawnRate - spawnAcceleration)
                    boxSpawnCooldown = newSpawnRate
                }
            }
            
            if let character = character {
                if !activeBoxes.isEmpty {
                    for (_, laneIndex, _) in activeBoxes {
                        if laneIndex == currentLane {
                            // Cek collision berdasarkan frame
                            if let boxNode = activeBoxes.first(where: { $0.laneIndex == laneIndex })?.node {
                                let boxFrame = boxNode.frame
                                let characterFrame = character.frame
                                if boxFrame.intersects(characterFrame) && !isInCollisionCooldown {
                                    
                                    let yOverlap = characterFrame.intersection(boxFrame).height
                                    if yOverlap >= collisionThreshold {
                                        handleCharacterCrash()
                                        isInCollisionCooldown = true
                                        lastCollisionTime = currentTime
                                        break
                                    }
                                }
                            }
                        }
                    }
                } else if activeBoxes.isEmpty && isWallSpawned {
                    let yOverlap = character.frame.intersection(wall.frame).height
                    if yOverlap >= collisionThreshold && !isInCollisionCooldown {
                        handleCharacterCrash()
                        isInCollisionCooldown = true
                        lastCollisionTime = currentTime
                    }
                }
                
                if isInCollisionCooldown && currentTime - lastCollisionTime >  max(minBoxSpawnRate, boxSpawnRate - spawnAcceleration)  + 0.5{
                    isInCollisionCooldown = false
                }
            }
        }
    }
    

    
    private func handleCharacterCrash() {
        guard let character = character else { return }
        
        collisionCount += 1
        
        // khusus tabrakan ke tiga yang mouth closing
        if collisionCount >= maxCollisions {
            showJumpscare(imageName: specialJumpscareImage)
            
            // ini jeda biar mulus tp ga terlalu signifikan si
            let waitAction = SKAction.wait(forDuration: 1.0)
            let gameOverAction = SKAction.run { [weak self] in
                self?.gameOver()
            }
            self.run(SKAction.sequence([waitAction, gameOverAction]))
            
        } else {
            // else -> collision pertama & ke dua
            
            // random gambar jumpscare
            if let randomImage = randomJumpscareImages.randomElement() {
                showJumpscare(imageName: randomImage)
            }
            
            // Karakter berkedip
            let blink = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.0, duration: 0.25),
                SKAction.fadeAlpha(to: 1.0, duration: 0.25)
            ])
            let repeatBlink = SKAction.repeat(blink, count: 4)
            character.run(repeatBlink)
        }
    }

    private func showJumpscare(imageName: String) {
        guard let overlay = crashOverlay else { return }
        
        overlay.texture = SKTexture(imageNamed: imageName)
        
        overlay.removeAllActions()
        overlay.alpha = 0
        overlay.run(SKAction.sequence([
            SKAction.fadeAlpha(to: 1.0, duration: 0.1),
            SKAction.wait(forDuration: 0.5),
            SKAction.fadeAlpha(to: 0.0, duration: 0.5)
        ]))
    }

    private func gameOver() {
        isGameOver = true
        timer?.invalidate() // stop timer skor
        // self.isPaused = true

        character?.removeAllActions()
                for boxData in activeBoxes {
                    boxData.node.removeAllActions()
                }
        
        // Display total score
        gameOverNode = SKNode()
        gameOverNode?.zPosition = 2000

        let overlay = SKSpriteNode(color: .black, size: self.size)
        overlay.alpha = 0.8
        overlay.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        gameOverNode?.addChild(overlay)

        // game over -> gambar yg fida bikin
        let gameOverImage = SKSpriteNode(imageNamed: "GameOverText")
        gameOverImage.setScale(0.8)
        gameOverImage.position = CGPoint(x: size.width / 2, y: size.height * 0.65)
        gameOverNode?.addChild(gameOverImage)
        
        // Text Score (Di game over)
        let finalScoreLabel = SKLabelNode(fontNamed: "Arial-SemiBoldMT")
        finalScoreLabel.text = "Your Score: \(score)"
        finalScoreLabel.fontSize = 50
        finalScoreLabel.fontColor = .white
        finalScoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.40)
        gameOverNode?.addChild(finalScoreLabel)
        
        
        // Text nyuruh nod
        let label = SKLabelNode(fontNamed: "Arial-SemiBoldMT")
        label.text = "Nod Your Head to Restart"
        label.fontSize = 40
        label.fontColor = .white
        label.position = CGPoint(x: size.width / 2, y: size.height * 0.30)
        self.restartLabel = label
        gameOverNode?.addChild(self.restartLabel!)
        if let gameOverNode = gameOverNode {
            addChild(gameOverNode)
        }
    }
    

    func restartGame() {
            self.isPaused = false
            
            if let view = self.view {
                let startScene = StartScene()
                startScene.scaleMode = self.scaleMode
                
                let transition = SKTransition.fade(withDuration: 0.8)
                view.presentScene(startScene, transition: transition)
            }
        }
    
    private func setupCharacter() {
        let char = SKSpriteNode()
        
        char.size = CGSize(width: 200, height: 200)
        char.zPosition = 1
        char.anchorPoint = CGPoint(x: 0, y: 0)
        character = char
        idleAnimation()
        moveCharacter(to: 0, animated: false)
        addChild(char)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
    }
    
    
    private func moveCharacter(to laneIndex: Int, animated: Bool = true) {
        guard let character = character else { return }
        let widthX1 =  laneEdgeX(laneIndex: laneIndex, y: 50)
        let widthX2 =  laneEdgeX(laneIndex: laneIndex + 1, y: 50)
        let charY = character.position.y
        let charX = widthX1 + abs(widthX2 - widthX1) / 2 - character.size.width / 2
        if animated {
            let moveAction = SKAction.move(to: CGPoint(x: charX, y: charY), duration: 0.2)
            character.run( SKAction.sequence([
                moveAction,
                SKAction.run { [weak self] in
                    self?.idleAnimation()
                }
            ]))
        } else {
            character.position.x = charX
        }
        
        currentLane = laneIndex
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
            line.lineWidth = 2.5
            line.alpha = 0.3
            line.name = "laneLine"
            lanes.append(line)
            addChild(line)
        }
        currentBoxY = size.height - size.height / 3
    }
    
    
    private func playAnimation(named animationName: String) {
        guard let character = character else { return }
        let textures = (1...4).map { SKTexture(imageNamed: "char_\(animationName)_\($0)") }
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        let sequence = SKAction.sequence([animation, animation.reversed()])
        character.run(SKAction.repeatForever(sequence))
        
        character.removeAction(forKey: "run")
        character.run(SKAction.repeatForever(sequence), withKey: "run")
    }
    
    
    private func setupMouths() {
        let y = size.height - size.height / 3 - 280
        
        let mouthNodeFront = SKSpriteNode(imageNamed: "bottom_mouth")
        mouthNodeFront.zPosition = -10
        mouthNodeFront.setScale(0.6)
        mouthNodeFront.position = CGPoint(x: size.width / 2, y: y)
        addChild(mouthNodeFront)
        mouthFront = mouthNodeFront
        
        
        let mouthNodeBack = SKSpriteNode(imageNamed: "top_mouth")
        mouthNodeBack.zPosition = 10
        mouthNodeBack.setScale(0.6)

        mouthNodeBack.position = CGPoint(x: size.width / 2, y: y)
        
        addChild(mouthNodeBack)
        mouthBack = mouthNodeBack
    }
    
    func advanceMouthStage() {
        guard let mouthFront = mouthFront, let mouthBack = mouthBack else { return }
        
        let scale: CGFloat
        let yOffset: CGFloat
                
        switch mouthStage {
        case 0:
            scale = 0.6
            yOffset = -280
        case 1:
            scale = 0.8
            yOffset = -400
        case 2:
            scale = 1.0
            yOffset = -550
        default:
            scale = 0.6
            yOffset = -280
        }
        
        let newY = size.height - size.height / 3 + yOffset
        let move = SKAction.move(to: CGPoint(x: size.width / 2, y: newY), duration: 0.2)
        let resize = SKAction.scale(to: scale, duration: 0.2)
        mouthFront.run(SKAction.group([move, resize]))
        mouthBack.run(SKAction.group([move, resize]))
    }
    
    private func setupCrashOverlay() {
        
        let overlay = SKSpriteNode()
        overlay.size = size
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 999
        overlay.alpha = 0
        addChild(overlay)
        crashOverlay = overlay
    }
    
    private func getCurrentMouthYPosition() -> CGFloat {
        switch mouthStage {
        case 0: return size.height - size.height / 3 - 280
        case 1: return size.height - size.height / 3 - 400
        case 2: return size.height - size.height / 3 - 550
        default: return size.height - size.height / 3 - 280
        }
    }
}


extension Tiles: GameDelegate {
    
    func blinkDetected() {
        
    }
    
    // logic node 2 orang
    func nodDetected(playerIndex: Int) {
        guard isGameOver else { return }
        
        if (playerIndex == 0 && playerOneNodded) || (playerIndex == 1 && playerTwoNodded) {
            return
        }

        if playerIndex == 0 {
            playerOneNodded = true
        } else if playerIndex == 1 {
            playerTwoNodded = true
        }
        
       
        if playerOneNodded && playerTwoNodded {
            
            restartLabel?.text = "Restarting..."
            restartGame()
        } else {
            
            if playerOneNodded {
                restartLabel?.text = "Player 1 Ready!"
                restartLabel?.fontSize = 30
            } else if playerTwoNodded {
                restartLabel?.text = "Player 2 Ready!"
                restartLabel?.fontSize = 30
            }
        }
    }
 

    func moveRight() {
        guard !isGameOver else { return }
        if characterLaneIndex < numberOfLanes - 1 {
            characterLaneIndex += 1
            moveCharacter(to: characterLaneIndex)
        }
    }
    
    func moveLeft() {
        guard !isGameOver else { return }
        if characterLaneIndex > 0 {
            characterLaneIndex -= 1
            moveCharacter(to: characterLaneIndex)
        }
    }
    
    func idleAnimation() {
        playAnimation(named: "idle")
    }
    
    func rightAnimation() {
        playAnimation(named: "right")
    }
    
    func leftAnimation() {
        playAnimation(named: "left")
    }
    
    func crashAnimation() {
        playAnimation(named: "crash")
    }
    
    func crashInverseAnimation() {
        playAnimation(named: "crash_inverse")
    }
}


extension SKView {
    @objc func handleMouthTap(_ sender: UITapGestureRecognizer) {
        if let scene = self.scene as? Tiles {
            guard !scene.isGameOver else { return }
            scene.advanceMouthStage()
        }
    }
}


struct TilesView_Preview: PreviewProvider {
    static var previews: some View {
        SpriteView(scene: Tiles(cameraManager: CameraManager()))
            .ignoresSafeArea()
    }
}

