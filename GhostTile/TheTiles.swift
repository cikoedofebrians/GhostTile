//
//  TheTiles.swift
//  GhostTile
//
//  Created by Ciko Edo Febrian on 09/06/25.
//

import SpriteKit
import SwiftUI

class TheTiles: SKScene {
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
    var currentLaneSpan: Int = 1
    var boxes: [SKSpriteNode] = []
    var activeBoxes: [(node: SKSpriteNode, laneIndex: Int, y: CGFloat)] = []
    var boxSpawnCooldown: TimeInterval = 0
    var boxSpawnRate: TimeInterval = 2.5
    var spawnAcceleration: TimeInterval = 0.001
    let minBoxSpawnRate: TimeInterval = 0.5
    var lastSpawnedLanes: [Int] = []
    var totalElapsedTime: TimeInterval = 0
    var hasTriggeredAllLaneSpawn = false
    var lastAllLaneSpawnTime: TimeInterval = 0
    var currentSpeedMultiplier: CGFloat = 1.0
    var isSlowedForAllLaneSpawn: Bool = false
    private var mouthFront: SKSpriteNode?
    private var mouthBack: SKSpriteNode?
    private var mouthStage: Int = 0
    var isCrashing = false
    var currentLane: Int = 0
    var isInCollisionCooldown = false
    var lastCollisionTime: TimeInterval = 0
    let collisionCooldownDuration: TimeInterval = 2.0
    let collisionThreshold: CGFloat = 100
    
    // Blink
    var blinkPopup: SKLabelNode?
    var isBlinkChallengeActive = false
    var blinkCount = 0
    let requiredBlinks = 5
    
    var blinkDetector: BlinkDetector?
    
    var onLeftBlinkDetected: (() -> Void)?
    var onRightBlinkDetected: (() -> Void)?
    var onBothBlinkDetected: (() -> Void)?


    
    override init() {
        super.init(size: .zero)
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.scaleMode = .resizeFill
        self.backgroundColor = .black
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.scaleMode = .resizeFill
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
            setupPerspectiveLines()
            setupCharacter()
            setupMouths()

            let tap = UITapGestureRecognizer(target: view, action: #selector(view.handleMouthTap(_:)))
            view.addGestureRecognizer(tap)
        
        blinkDetector = BlinkDetector()
        blinkDetector?.onLeftBlinkDetected = { [weak self] in
            self?.registerBlink()
        }
        blinkDetector?.onRightBlinkDetected = { [weak self] in
            self?.registerBlink()
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
        boxSpawnCooldown -= 1/60
        totalElapsedTime += 1.0 / 60.0
        
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
            
            if !isBlinkChallengeActive && checkAllLanesBlocked() {
                showBlinkPopup()
                isBlinkChallengeActive = true
            }

            
        }
        
        if boxSpawnCooldown <= 0 {
            var selectedLanes: [Int] = []
            
            if totalElapsedTime - lastAllLaneSpawnTime >= 20 {
                selectedLanes = [0, 1, 2, 3]
                lastAllLaneSpawnTime = totalElapsedTime
                currentSpeedMultiplier = 0.5
                isSlowedForAllLaneSpawn = true
            } else {
                let numberOfLanesToCover = Int.random(in: 1...3)
                
                let possibleCombinations = [
                    [0, 1, 2],
                    [0, 1, 3],
                    [0, 2, 3],
                    [1, 2, 3],
                    [0, 1],
                    [0, 2],
                    [0, 3],
                    [1, 2],
                    [1, 3],
                    [2, 3],
                    [0],
                    [1],
                    [2],
                    [3]
                ]
                
                let candidates = possibleCombinations.filter { $0.count == numberOfLanesToCover }
                let validCandidates = candidates.filter { candidate in
                    !Set(candidate).isSubset(of: Set(lastSpawnedLanes))
                }
                
                guard let chosen = (validCandidates.isEmpty ? candidates : validCandidates).randomElement() else { return }
                selectedLanes = chosen
            }
            
            let y = getCurrentMouthYPosition() + CGFloat.random(in: 200...300)
            
            for laneIndex in selectedLanes {
                let scale = calculateScale(forY: y)
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
                box.run(SKAction.fadeAlpha(to: 1, duration: 0.5))
                
                addChild(box)
                activeBoxes.append((node: box, laneIndex: laneIndex, y: y))
            }
            
            lastSpawnedLanes = selectedLanes
            boxSpawnCooldown = boxSpawnRate
            boxSpawnRate = max(minBoxSpawnRate, boxSpawnRate - spawnAcceleration)
        }
        if let character = character {
            let characterFrame = character.frame
            for (box, laneIndex, y) in activeBoxes {
                let boxFrame = box.frame
                let characterFrame = character.frame

                if laneIndex == currentLane {
                    let yOverlap = characterFrame.intersection(boxFrame).height

                    if yOverlap >= collisionThreshold && !isInCollisionCooldown {
                        handleCharacterCrash()
                        isInCollisionCooldown = true
                        lastCollisionTime = currentTime
                        break
                        
                        
                    }
                }
            }
            
            if isInCollisionCooldown && currentTime - lastCollisionTime > collisionCooldownDuration {
                isInCollisionCooldown = false
            }
        }
    }
    
    func registerBlink() {
        guard isBlinkChallengeActive else { return }
        blinkCount += 1
        
        if let counterLabel = childNode(withName: "blinkCounterLabel") as? SKLabelNode {
            counterLabel.text = "Blink \(blinkCount)/\(requiredBlinks)"
        }

        if blinkCount >= requiredBlinks {
            clearAllObstacles()
            hideBlinkPopup()
            isBlinkChallengeActive = false
            blinkCount = 0
        }
    }


    private func checkAllLanesBlocked() -> Bool {
        
        var yGroups: [Int: Set<Int>] = [:]
        
        for (_, laneIndex, y) in activeBoxes {
            let roundedY = Int(y / 50)  // Group by Y level
            yGroups[roundedY, default: []].insert(laneIndex)
        }
        
        for lanes in yGroups.values {
            if lanes.count == numberOfLanes {
                return true
            }
        }
        return false
    }


    private func showBlinkPopup() {
        guard blinkPopup == nil else { return }

        // Title label
        let label = SKLabelNode(text: "Blink 5x to clear path!")
        label.fontName = "AvenirNext-Bold"
        label.fontSize = 42
        label.position = CGPoint(x: size.width / 2, y: size.height / 2 + 30)
        label.zPosition = 100
        label.alpha = 0.0
        addChild(label)
        
        // Counter label
        let counterLabel = SKLabelNode(text: "Blink 0/\(requiredBlinks)")
        counterLabel.fontName = "AvenirNext-Bold"
        counterLabel.fontSize = 36
        counterLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 - 30)
        counterLabel.zPosition = 100
        counterLabel.alpha = 0.0
        counterLabel.name = "blinkCounterLabel"
        addChild(counterLabel)

        blinkPopup = label

        label.run(SKAction.fadeIn(withDuration: 0.5))
        counterLabel.run(SKAction.fadeIn(withDuration: 0.5))
    }


    private func hideBlinkPopup() {
        blinkPopup?.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        blinkPopup = nil
        
        if let counterLabel = childNode(withName: "blinkCounterLabel") {
            counterLabel.run(SKAction.sequence([
                SKAction.fadeOut(withDuration: 0.5),
                SKAction.removeFromParent()
            ]))
        }
    }


    private func clearAllObstacles() {
        for (box, _, _) in activeBoxes {
            box.removeFromParent()
        }
        activeBoxes.removeAll()
    }

    
    private func handleCharacterCrash() {
        guard let character = character else { return }
        
        let blink = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.2, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])
        let repeatBlink = SKAction.repeat(blink, count: 5)
        character.run(repeatBlink, withKey: "blink")
        advanceMouthStage()
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
        self.currentLane = laneIndex
        
        let charX = widthX1 + abs(widthX2 - widthX1) / 2 - character.size.width / 2
        if animated {
            let moveAction = SKAction.moveTo(x: charX, duration: 0.2)
            character.run( SKAction.sequence([
                moveAction,
                SKAction.run { [weak self] in
                    self?.idleAnimation()
                }
            ]))
        } else {
            character.position.x = charX
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
            line.lineWidth = 2
            line.alpha = 0.3
            line.alpha = 0.3
            line.name = "laneLine"
            lanes.append(line)
            addChild(line)
        }
        currentBoxY = size.height - size.height / 3
        let horizonLine = SKShapeNode(rect: CGRect(x: 0, y: size.height - size.height/3, width: size.width, height: 2))
        horizonLine.fillColor = .black
        horizonLine.alpha = 0.2
        horizonLine.name = "horizonLine"
        addChild(horizonLine)
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
    
    private func playAnimation(named animationName: String) {
        guard let character = character else { return }
        
        let textures = (1...4).map { SKTexture(imageNamed: "char_\(animationName)_\($0)") }
        let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
        let sequence = SKAction.sequence([animation, animation.reversed()])
        
        character.removeAction(forKey: "run")
        character.run(SKAction.repeatForever(sequence), withKey: "run")
    }
    
    
    private func setupMouths() {
        let mouthNodeFront = SKSpriteNode(imageNamed: "bottom_mouth")
        mouthNodeFront.zPosition = 3
        mouthNodeFront.setScale(0.6)
        mouthNodeFront.position = CGPoint(
            x: size.width / 2,
            y: size.height - size.height / 3 - 280
        )
        addChild(mouthNodeFront)
        mouthFront = mouthNodeFront

        let mouthNodeBack = SKSpriteNode(imageNamed: "top_mouth")
        mouthNodeBack.zPosition = -1
        mouthNodeBack.setScale(0.6)
        mouthNodeBack.position = CGPoint(
            x: size.width / 2,
            y: size.height - size.height / 3 - 280
        )
        addChild(mouthNodeBack)
        mouthBack = mouthNodeBack
    }

    
    func advanceMouthStage() {
            guard let mouthFront = mouthFront, let mouthBack = mouthBack else { return }
            mouthStage += 1
            if mouthStage > 2 { mouthStage = 0 }
            
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
    
    private func getCurrentMouthYPosition() -> CGFloat {
        switch mouthStage {
        case 0:
            return size.height - size.height / 3 - 280
        case 1:
            return size.height - size.height / 3 - 400
        case 2:
            return size.height - size.height / 3 - 550
        default:
            return size.height - size.height / 3 - 280
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
        if let scene = self.scene as? TheTiles {
            scene.advanceMouthStage()
        }
    }
}
