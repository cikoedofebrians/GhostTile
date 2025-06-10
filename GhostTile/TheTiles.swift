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
    
    override init() {
        super.init(size: .zero)
        self.anchorPoint = CGPoint(x: 0, y: 0)
        self.scaleMode = .resizeFill
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
        if lanes.count > 1 {
            let widthX1 = laneEdgeX(laneIndex: currentLaneIndex, y: currentBoxY)
            let widthX2 = laneEdgeX(laneIndex: currentLaneIndex + 1, y: currentBoxY)
            
            let width = abs(widthX2 - widthX1)
            if box != nil {
                let scale = calculateScale(forY: currentBoxY)
                box?.size = CGSize(width: width, height: baseHeight * scale)
                box!.position = CGPoint(x: widthX1, y: currentBoxY)
                if box!.position.y < 0 - (baseHeight * scale){
                    box!.removeFromParent()
                    box = nil
                    currentBoxY = size.height - size.height / 3
                    currentLaneIndex = Int.random(in: 0..<numberOfLanes - 1)
                }
            } else {
                let scale = calculateScale(forY: currentBoxY)
                let newBox = SKSpriteNode()
                newBox.texture = SKTexture(imageNamed: "obstacle_1")
                newBox.anchorPoint = CGPoint(x: 0, y: 0) // Center anchor point
                newBox.size = CGSize(width: width, height: baseHeight * scale)
                newBox.alpha = 0
                newBox.run(
                    SKAction.fadeAlpha(to: 1, duration: 0.5)
                )
                newBox.position = CGPoint(x: widthX1 + width / 2, y: currentBoxY + baseHeight * scale / 2)
                box = newBox
                addChild(newBox)
                let textures = (1...4).map { SKTexture(imageNamed: "obstacle_\($0)") }
                let animation = SKAction.animate(with: textures, timePerFrame: 0.1)
                newBox.run(SKAction.repeatForever(animation))
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


struct TheTilesView: View {
    @StateObject var cameraManager: CameraManager = CameraManager()
    @State private var gameScene: TheTiles = TheTiles()
    
    var body: some View {
        SpriteView(scene: gameScene)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Perspective Runner")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: cameraManager.lastRollSide) { oldValue, newValue in
                if oldValue != newValue {
                    switch newValue {
                    case .left:
                        gameScene.moveLeft()
                    case .right:
                        gameScene.moveRight()
                    default:
                        break
                    }
                }
            }
            .onChange(of: cameraManager.faceRollSide) { oldValue, newValue in
                guard newValue.count == 2,
                      let first = newValue.first,
                      let second = newValue.last else { return }
                
                if first == .none && second == .right || first == .right && second == .none {
                    gameScene.rightAnimation()
                } else if first == .none && second == .left || first == .left && second == .none {
                    gameScene.leftAnimation()
                } else if first == .right && second == .left {
                    gameScene.crashAnimation()
                } else if first == .left && second == .right {
                    gameScene.crashInverseAnimation()
                } else if first == .none && second == .none {
                    gameScene.idleAnimation()
                }
            }
    }
}


#Preview {
    TheTilesView()
}

