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
    
    private var mouthFront: SKSpriteNode?
    private var mouthBack: SKSpriteNode?
    private var mouthStage: Int = 0
    
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
    
    private func setupMouths() {

            let mouthNodeFront = SKSpriteNode(imageNamed: "top_mouth")
            mouthNodeFront.zPosition = -1
            mouthNodeFront.setScale(0.45)
            mouthNodeFront.position = CGPoint(x: size.width / 2, y: size.height / 3)
            addChild(mouthNodeFront)
            mouthFront = mouthNodeFront
            
            let mouthNodeBack = SKSpriteNode(imageNamed: "bottom_mouth")
            mouthNodeBack.zPosition = 3
            mouthNodeBack.setScale(0.45)
            mouthNodeBack.position = CGPoint(x: size.width / 2, y: size.height - size.height / 3 - 100)
            addChild(mouthNodeBack)
            mouthBack = mouthNodeBack
        
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
    
    override func update(_ currentTime: TimeInterval) {
        if lanes.count > 1 {
            let widthX1 = laneEdgeX(laneIndex: currentLaneIndex, y: currentBoxY)
            let widthX2 = laneEdgeX(laneIndex: currentLaneIndex + 1, y: currentBoxY)
            
            let width = abs(widthX2 - widthX1)
            // Instead of creating a shape with CGRect offsets
            let scale = calculateScale(forY: currentBoxY)
            
            // Create or update sprite
            if box != nil {
                // Update existing sprite
                let newSize = CGSize(width: width, height: baseHeight * scale)
                box!.size = newSize
                box!.position = CGPoint(x: widthX1 + width / 2, y: currentBoxY)
                
                if box!.position.y < 0 - (baseHeight * scale){
                    box!.removeFromParent()
                    box = nil
                    currentBoxY = size.height - size.height / 3
                    currentLaneIndex = Int.random(in: 0..<numberOfLanes - 1)
                }
            } else {
                // Create new sprite
                let newSize = CGSize(width: width, height: baseHeight * scale)
                let newBox = SKSpriteNode(color: .white, size: newSize)
                
                // Set anchor point for bottom-center positioning
                newBox.anchorPoint = CGPoint(x: 0.5, y: 0.0)
                newBox.alpha = 0
                newBox.run(SKAction.fadeAlpha(to: 1, duration: 0.5))
                newBox.position = CGPoint(x: widthX1 + width / 2, y: currentBoxY)
                
                let textures = (1...3).map { SKTexture(imageNamed: "obstacle_\($0)") }
                let animation = SKAction.animate(with: textures, timePerFrame: 0.2)
                let fullAnimation = SKAction.sequence([animation, animation.reversed()])
                newBox.run(SKAction.repeatForever(fullAnimation))
                box = newBox
                addChild(newBox)
            }
            currentBoxY -= 6 * calculateScale(forY: currentBoxY)
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
        horizonLine.fillColor = .white
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
        character.run(SKAction.repeatForever(sequence))
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
