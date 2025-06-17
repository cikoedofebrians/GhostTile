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
    
    var gameOverAudioPlayer: AVAudioPlayer?
    var backgroundMusicPlayer: AVAudioPlayer?
    var shootingAudioPlayer: AVAudioPlayer?
    var jumpscareAudioPlayer: AVAudioPlayer?
    let randomJumpscareSounds: [String] = ["jumpscare-monsterscr", "jumpscare-kaget", "jumpsc-whoosh"]
    
    @Binding var shouldStartGame: Bool
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
    var wallHealth: Int = 30
    var isWallSpawned: Bool = false
    var wallY: CGFloat = 0.0
    var crashOverlay : SKSpriteNode?
    var bulletTimer: Timer?
    let cameraManager: CameraManager
    var hasBlinked: Bool = false
    let blink: SKSpriteNode = {
        let blinkNode = SKSpriteNode()
        blinkNode.color = .redBlink
        blinkNode.anchorPoint = CGPoint(x: 0, y: 0)
        blinkNode.alpha = 0
        blinkNode.zPosition = 1000
        return blinkNode
    }()
    
    var collisionCount: Int = 0
    let maxCollisions: Int = 3
    var isGameOver: Bool = false
    var gameOverNode: SKNode?
    let randomJumpscareImages: [String] = ["jumpscare", "jumpscare2", "jumpscare3", "jumpscare4"]
    var restartLabel: SKLabelNode?
    
    
    var health: Int = 3 {
        didSet {
            if health <= 0 {
                let waitAction = SKAction.wait(forDuration: 1.0)
                let gameOverAction = SKAction.run { [weak self] in
                    self?.gameOver()
                }
                self.run(SKAction.sequence([waitAction, gameOverAction]))
            }
        }
    }
    
    func setupBackgroundMusic() {
            
            guard let url = Bundle.main.url(forResource: "run-song", withExtension: "mp3") else {
                print("Error")
                return
            }
            
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
                backgroundMusicPlayer?.numberOfLoops = -1
                backgroundMusicPlayer?.prepareToPlay()
                backgroundMusicPlayer?.play()
            } catch {
                print("Error")
            }
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
    
    init(cameraManager: CameraManager, shouldStartGame: Binding<Bool>) {
        self._shouldStartGame = shouldStartGame
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
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
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
        setupBackground()
        setupPerspectiveLines()
        setupCharacter()
        setupMouths()
        setupScore()
        setupAcceleration()
        setupCrashOverlay()
        setupBackgroundMusic()
        
        let tap = UITapGestureRecognizer(target: view, action: #selector(view.handleMouthTap(_:)))
        view.addGestureRecognizer(tap)
    }
    
    func shootBullet() {
        //        if bulletTimer == nil && isWallSpawned {
        //            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] timer in
        //                print("\(timer)")
        //                guard let self = self else { return }
        //                if !isWallSpawned {
        //                    timer.invalidate()
        //                    bulletTimer = nil
        //                    return
        //                }
        //                guard let character = character else { return }
        //                let bullet = SKSpriteNode(color: .red, size: CGSize(width: 10, height: 20))
        //                bullet.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        //                bullet.position = CGPoint(x: character.position.x + character.size.width / 2, y: character.position.y + character.size.height / 2)
        //                addChild(bullet)
        //                let moveAction = SKAction.moveTo(y: size.height - size.height / 3, duration: 1.0)
        //                bullet.run(moveAction) {
        //                    bullet.removeFromParent()
        //                }
        //            }
        //        }
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
                wallY -= 2 * scale
                let widthX1 = laneEdgeX(laneIndex: 0, y: wallY)
                let widthX2 = laneEdgeX(laneIndex: 4, y: wallY)
                let width = abs(widthX2 - widthX1)
                wall.size = CGSize(width: width, height: 160 * scale)
                wall.position = CGPoint(x: widthX1 + width / 2, y: wallY)
                
                if wallY < -wall.size.height {
                    resetWall()
                }
            }
            if isWallSpawned && !activeBoxes.isEmpty || !isWallSpawned {
                for (index, boxData) in activeBoxes.enumerated().reversed() {
                    var (box, laneIndex, y) = boxData
                    
                    let scale = calculateScale(forY: y)
                    let widthX1 = laneEdgeX(laneIndex: laneIndex, y: y)
                    let widthX2 = laneEdgeX(laneIndex: laneIndex + 1, y: y)
                    let width = abs(widthX2 - widthX1)
                    
                    box.size = CGSize(width: width, height: baseHeight * scale)
                    box.position = CGPoint(x: widthX1 + width / 2, y: y)
                    
                    y -= 6 * scale
                    activeBoxes[index].y = y
                    
                    if y < -box.size.height {
                        box.removeFromParent()
                        activeBoxes.remove(at: index)
                    }
                }
                
                let y = size.height - size.height / 3
                let scale = calculateScale(forY: y)
                
                if boxSpawnCooldown <= 0 {
                    var selectedLanes: [Int] = []
                    
                    //                    if totalElapsedTime - lastAllLaneSpawnTime >= CGFloat.random(in: 10...20) && !isWallSpawned {
                    if totalElapsedTime - lastAllLaneSpawnTime >= 10 && !isWallSpawned {
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
                        let allCombinations: [[Int]] = [
                            [0],
                            [1],
                            [2],
                            [3],
                            [0, 1],
                            [0, 2],
                            [0, 3],
                            [1, 2],
                            [1, 3],
                            [2, 3],
                            [0, 1, 2],
                            [0, 1, 3],
                            [0, 2, 3],
                            [1, 2, 3]
                        ]
                        
                        let maxBoxCount: Int
                        let minBoxCount: Int
                        
                        switch totalElapsedTime {
                        case 0..<20:
                            minBoxCount = 1
                            maxBoxCount = 2
                        case 20..<40:
                            minBoxCount = 1
                            maxBoxCount = 3
                        case 40..<60:
                            minBoxCount = 2
                            maxBoxCount = 3
                        default:
                            minBoxCount = 3
                            maxBoxCount = 3
                        }
                        
                        let possibleCombinations = allCombinations.filter {
                            $0.count >= minBoxCount && $0.count <= maxBoxCount
                        }
                        
                        let candidates = possibleCombinations.filter { $0.count == numberOfLanesToCover }
                        let validCandidates = candidates.filter { candidate in
                            !Set(candidate).isSubset(of: Set(lastSpawnedLanes))
                        }
                        
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
                    spawnAcceleration += 0.08
                    let newSpawnRate = max(minBoxSpawnRate, boxSpawnRate - spawnAcceleration)
                    boxSpawnCooldown = newSpawnRate
                }
            }
            
            if let character = character {
                if !activeBoxes.isEmpty {
                    for (box, laneIndex, _) in activeBoxes {
                        let boxFrame = box.frame
                        let characterFrame = character.frame
                        
                        if laneIndex == currentLane {
                            let yOverlap = characterFrame.intersection(boxFrame).height
                            
                            if yOverlap >= collisionThreshold && !isInCollisionCooldown {
                                health -= 1
                                advanceMouthStage()
                                handleCharacterCrash()
                                isInCollisionCooldown = true
                                lastCollisionTime = currentTime
                                break
                            }
                        }
                    }
                }
                else if activeBoxes.isEmpty && isWallSpawned {
                    let yOverlap = character.frame.intersection(wall.frame).height
                    if yOverlap >= collisionThreshold && !isInCollisionCooldown {
                        health -= 1
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
        
        if health > 0 {
            // else -> collision pertama & ke dua
            
            // random gambar jumpscare
            if let randomImage = randomJumpscareImages.randomElement() {
                showJumpscare(imageName: randomImage)
            }
            
            playRandomJumpscareSound()
            
            // Karakter berkedip
            let blink = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.0, duration: 0.25),
                SKAction.fadeAlpha(to: 1.0, duration: 0.25)
            ])
            let repeatBlink = SKAction.repeat(blink, count: 4)
            character.run(repeatBlink)
        }
    }
    
    private func playRandomJumpscareSound() {
           
            guard let soundName = randomJumpscareSounds.randomElement() else {
                print("Gak iso")
                return
            }
            
          
            guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
                print("Error")
                return
            }
            
        
            do {
                jumpscareAudioPlayer = try AVAudioPlayer(contentsOf: url)
                jumpscareAudioPlayer?.numberOfLoops = 0
                jumpscareAudioPlayer?.volume = 10.0
                jumpscareAudioPlayer?.play()
            } catch {
                print("Error")
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
    
    private func gameOver() {
        isWallSpawned = false
        isGameOver = true
        timer?.invalidate()
        
        character?.removeAllActions()
        
        gameOverNode = SKNode()
        gameOverNode?.zPosition = 2000
        
        let overlay = SKSpriteNode(color: .black, size: self.size)
        overlay.alpha = 0.8
        overlay.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        gameOverNode?.addChild(overlay)
        
        // game over -> gambar yg fida bikin
        let gameOverImage = SKSpriteNode(imageNamed: "game_over_text")
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
        
        if let url = Bundle.main.url(forResource: "GameOverSong", withExtension: "mp3") {
                    do {
                        gameOverAudioPlayer = try AVAudioPlayer(contentsOf: url)
                        gameOverAudioPlayer?.numberOfLoops = 0
                        gameOverAudioPlayer?.play()
                    } catch {
                        print("Error")
                    }
                }
        
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
        
        switch health {
        case 3:
            scale = 0.6
            yOffset = -280
        case 2:
            scale = 0.8
            yOffset = -400
        case 1:
            scale = 1.0
            yOffset = -550
        case 0:
            scale = 1.4
            yOffset = -700
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
        let overlay = SKSpriteNode(imageNamed: "jumpscare")
        overlay.size = size
        overlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
        overlay.zPosition = 999
        overlay.alpha = 0
        addChild(overlay)
        crashOverlay = overlay
    }
    
    func resetWall() {
        DispatchQueue.main.async {
            self.isWallSpawned = false
            self.wallHealth = 30
            self.hasBlinked = false
            let textures = (1...6).map { SKTexture(imageNamed: "wall_\($0)") }
            let animation = SKAction.animate(with: textures, timePerFrame: 0.2)
            let fullAnimation = SKAction.sequence([animation, animation.reversed()])
            self.wall.run(SKAction.repeatForever(fullAnimation))
            self.wall.removeFromParent()
        }
    }
    
    private func blinkToFire() {
        
        if let url = Bundle.main.url(forResource: "shoot", withExtension: "mp3") {
                do {
                    shootingAudioPlayer = try AVAudioPlayer(contentsOf: url)
                    shootingAudioPlayer?.play()
                    shootingAudioPlayer?.volume = 8.0
                } catch {
                    print("Error")
                }
            }
            
        
        guard isWallSpawned, let character = character else { return }
        wall.alpha = 1.0
        let startY = character.position.y + character.size.height
        let laneIndex = currentLane
        
        let bullet = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 60))
        bullet.anchorPoint = CGPoint(x: 0.5, y: 0)
        bullet.zPosition = 5
        addChild(bullet)
        
        var currentBulletY = startY
        let updateInterval: TimeInterval = 0.5 / 60.0
        
        let updateAction = SKAction.run { [weak self, weak bullet] in
            guard let self = self, let bullet = bullet else { return }
            
            let scale = self.calculateScale(forY: currentBulletY)
            let widthX1 = self.laneEdgeX(laneIndex: laneIndex, y: currentBulletY)
            let widthX2 = self.laneEdgeX(laneIndex: laneIndex + 1, y: currentBulletY)
            let laneWidthAtY = abs(widthX2 - widthX1)
            
            bullet.size = CGSize(width: 10 * scale, height: 100 * scale)
            bullet.position = CGPoint(
                x: widthX1 + laneWidthAtY / 2,
                y: currentBulletY
            )
            
            let nextY = currentBulletY + 1
            let nextX1 = self.laneEdgeX(laneIndex: laneIndex, y: nextY)
            let nextX2 = self.laneEdgeX(laneIndex: laneIndex + 1, y: nextY)
            let nextCenterX = (nextX1 + nextX2) / 2
            
            let currentCenterX = widthX1 + laneWidthAtY / 2
            let deltaX = nextCenterX - currentCenterX
            let deltaY = nextY - currentBulletY
            let angle = atan2(deltaY, deltaX) - .pi/2
            
            bullet.zRotation = angle
            currentBulletY += 10 * scale
            
            self.checkBulletCollision(bullet: bullet, at: currentBulletY)
            
            if currentBulletY > self.size.height - self.size.height / 3 {
                bullet.removeFromParent()
            }
        }
        
        let waitAction = SKAction.wait(forDuration: updateInterval)
        let movementSequence = SKAction.sequence([updateAction, waitAction])
        let repeatMovement = SKAction.repeatForever(movementSequence)
        
        bullet.run(repeatMovement, withKey: "bulletMovement")
    }
    
    
    private func setupWallCrackTexture() {
        if wallHealth > 0 {
            let crackImageName: String
            
            if wallHealth >= 25 {
                wall.removeAllActions()
                crackImageName = "Crack-1"
            } else if wallHealth >= 20 {
                crackImageName = "Crack-2"
            } else if wallHealth >= 15 {
                crackImageName = "Crack-3"
            } else if wallHealth >= 10 {
                crackImageName = "Crack-4"
            } else if wallHealth >= 5 {
                crackImageName = "Crack-5"
            } else  {
                crackImageName = "Crack-6"
            }
            wall.texture = SKTexture(imageNamed: crackImageName)
        } else {
            destroyWall()
        }
    }
    
    private func destroyWall() {
        let fadeOut = SKAction.fadeOut(withDuration: 0.5)
        let reset = SKAction.run {
            self.resetWall()
        }
        
        if let particles = SKEmitterNode(fileNamed: "WallExplosion") {
            particles.position = wall.position
            particles.zPosition = wall.zPosition + 2
            addChild(particles)
            particles.run(SKAction.sequence([
                SKAction.wait(forDuration: 1.0),
                SKAction.removeFromParent()
            ]))
        }
        
        wall.run(SKAction.sequence([fadeOut, reset]))
    }
    
    private func checkBulletCollision(bullet: SKSpriteNode, at y: CGFloat) {
        if isWallSpawned {
            let bulletFrame = bullet.frame
            let wallFrame = CGRect(x: wall.frame.minX, y: wall.frame.minY + wall.frame.height / 2, width: wall.frame.width, height: wall.frame.height)
            
            DispatchQueue.main.async {
                if bulletFrame.intersects(wallFrame)  {
                    self.wallHealth -= 1
                    self.setupWallCrackTexture()
                    bullet.removeAllActions()
                    bullet.removeFromParent()
                }
            }
        }
    }
    
    var blinkCount: Int = 0
}


extension Tiles: GameDelegate {
    func nodDetected() {
        guard isGameOver else { return }
        shouldStartGame = false
    }
    
    
    func blinkDetected() {
        blinkCount += 1
        blinkToFire()
    }
    
    func moveRight() {
        if characterLaneIndex < numberOfLanes - 1 {
            characterLaneIndex += 1
            moveCharacter(to: characterLaneIndex)
        }
    }
    
    func moveLeft() {
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
        playAnimation(named: "inward")
    }
    
    func crashInverseAnimation() {
        playAnimation(named: "apart")
    }
}


extension SKView {
    @objc func handleMouthTap(_ sender: UITapGestureRecognizer) {
        if let scene = self.scene as? Tiles {
            scene.advanceMouthStage()
        }
    }
}


#Preview(body: {
    TilesView(shouldStartGame: .constant(true), cameraManager: CameraManager())
})



