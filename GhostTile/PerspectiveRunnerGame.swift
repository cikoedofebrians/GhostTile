import SwiftUI
import SpriteKit

// MARK: - Game Scene
class PerspectiveRunnerScene: SKScene {
    

    private let numberOfLanes = 4
    private let laneWidth: CGFloat = 100
    private let perspectiveDistance: CGFloat = 800
    private let gameSpeed: TimeInterval = 0.02
    
    // Game objects
    private var player: SKSpriteNode!
    private var currentLane = 1 // Center lane (0, 1, 2)
    private var obstacles: [SKSpriteNode] = []
    private var score = 0
    private var scoreLabel: SKLabelNode!
    private var isGameOver = false
    
    // Movement
    private var isMoving = false
    
    override func didMove(to view: SKView) {
        self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1.0)
        physicsWorld.gravity = CGVector.zero
        startGameLoop()
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Remove old lines and UI
        children.filter { $0.name == "laneLine" || $0.name == "horizonLine" || $0.name == "scoreLabel" || $0.name == "instructionLabel" }.forEach { $0.removeFromParent() }
        // Remove player if exists
        player?.removeFromParent()
        // Redraw everything that depends on size
        setupPerspectiveLines()
        setupPlayer()
        setupUI()
    }
    
    private func setupPerspectiveLines() {
        for i in 0...numberOfLanes {
            let line = SKShapeNode()
            let path = CGMutablePath()
            let baseX = CGFloat(i) * laneWidth - CGFloat(numberOfLanes) * laneWidth / 2
            let nearX = baseX * 1.5
            let farX = baseX * 0.3
            path.move(to: CGPoint(x: nearX, y: -size.height/2))
            path.addLine(to: CGPoint(x: farX, y: size.height/3))
            line.path = path
            line.strokeColor = .white
            line.lineWidth = 2
            line.alpha = 0.3
            line.name = "laneLine"
            addChild(line)
        }
        let horizonLine = SKShapeNode(rect: CGRect(x: -size.width/2, y: size.height/3, width: size.width, height: 2))
        horizonLine.fillColor = .white
        horizonLine.alpha = 0.2
        horizonLine.name = "horizonLine"
        addChild(horizonLine)
    }
    
    private func setupPlayer() {
        player = SKSpriteNode(color: .cyan, size: CGSize(width: 30, height: 30))
        player.position = CGPoint(x: 0, y: -size.height/4)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.categoryBitMask = 1
        player.physicsBody?.contactTestBitMask = 2
        player.physicsBody?.collisionBitMask = 0
        addChild(player)
    }
    
    private func setupUI() {
        scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
        scoreLabel.text = "Score: \(score)"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: -size.width/2 + 100, y: size.height/2 - 50)
        scoreLabel.name = "scoreLabel"
        addChild(scoreLabel)
        let instructionLabel = SKLabelNode(fontNamed: "Arial")
        instructionLabel.text = "Tap left/right to change lanes"
        instructionLabel.fontSize = 16
        instructionLabel.fontColor = .white
        instructionLabel.alpha = 0.7
        instructionLabel.position = CGPoint(x: 0, y: size.height/2 - 80)
        instructionLabel.name = "instructionLabel"
        addChild(instructionLabel)
    }
    
    private func startGameLoop() {
        let spawnAction = SKAction.run { [weak self] in
            self?.spawnObstacle()
        }
        let waitAction = SKAction.wait(forDuration: 1.5)
        let sequenceAction = SKAction.sequence([spawnAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequenceAction)
        
        run(repeatAction, withKey: "spawnObstacles")
        
        // Score increment
        let scoreAction = SKAction.run { [weak self] in
            self?.incrementScore()
        }
        let scoreWait = SKAction.wait(forDuration: 0.1)
        let scoreSequence = SKAction.sequence([scoreAction, scoreWait])
        let scoreRepeat = SKAction.repeatForever(scoreSequence)
        
        run(scoreRepeat, withKey: "scoreIncrement")
    }
    
    private func spawnObstacle() {
        guard !isGameOver else { return }
        
        let randomLane = Int.random(in: 0..<numberOfLanes)
        let obstacle = createObstacle(lane: randomLane)
        obstacles.append(obstacle)
        addChild(obstacle)
        
        // Animate obstacle moving towards camera with scaling
        animateObstacleTowardsCamera(obstacle, lane: randomLane)
    }
    
    private func createObstacle(lane: Int) -> SKSpriteNode {
        let obstacle = SKSpriteNode(color: .red, size: CGSize(width: 20, height: 200))
        
        // Start position (far away, small)
        let laneX = calculateLanePosition(lane: lane, depth: 1.0)
        obstacle.position = CGPoint(x: laneX, y: size.height/3)
        obstacle.setScale(0.3) // Start small (far away)
        
        // Physics
        obstacle.physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
        obstacle.physicsBody?.categoryBitMask = 2
        obstacle.physicsBody?.contactTestBitMask = 1
        obstacle.physicsBody?.collisionBitMask = 0
        obstacle.physicsBody?.isDynamic = false
        
        return obstacle
    }
    
    private func calculateLanePosition(lane: Int, depth: CGFloat) -> CGFloat {
        let baseX = CGFloat(lane) * laneWidth - CGFloat(numberOfLanes) * laneWidth / 2
        return baseX * depth
    }
    
    private func animateObstacleTowardsCamera(_ obstacle: SKSpriteNode, lane: Int) {
        // Create multiple keyframes for smooth perspective animation
        var actions: [SKAction] = []
        
        let totalFrames = 50
        for frame in 1...totalFrames {
            let progress = CGFloat(frame) / CGFloat(totalFrames)
            let depth = 1.0 + progress * 1.5 // From 1.0 to 2.5
            let scale = 0.3 + progress * 0.7 // From 0.3 to 1.0
            
            let newX = calculateLanePosition(lane: lane, depth: depth)
            let newY = size.height/3 - progress * (size.height/3 + size.height/4)
            
            let moveAction = SKAction.move(to: CGPoint(x: newX, y: newY), duration: gameSpeed)
            let scaleAction = SKAction.scale(to: scale, duration: gameSpeed)
            let combinedAction = SKAction.group([moveAction, scaleAction])
            
            actions.append(combinedAction)
        }
        
        let sequenceAction = SKAction.sequence(actions)
        let removeAction = SKAction.removeFromParent()
        let fullSequence = SKAction.sequence([sequenceAction, removeAction])
        
        obstacle.run(fullSequence) { [weak self] in
            self?.obstacles.removeAll { $0 == obstacle }
        }
    }
    
    private func incrementScore() {
        guard !isGameOver else { return }
        score += 1
        scoreLabel.text = "Score: \(score)"
    }
    
    private func movePlayer(to lane: Int) {
        guard !isMoving && !isGameOver else { return }
        
        isMoving = true
        currentLane = max(0, min(numberOfLanes - 1, lane))
        
        let targetX = calculateLanePosition(lane: currentLane, depth: 1.5)
        let moveAction = SKAction.moveTo(x: targetX, duration: 0.2)
        moveAction.timingMode = .easeOut
        
        player.run(moveAction) { [weak self] in
            self?.isMoving = false
        }
    }
    
    private func gameOver() {
        isGameOver = true
        removeAllActions()
        
        // Stop all obstacles
        for obstacle in obstacles {
            obstacle.removeAllActions()
        }
        
        // Show game over screen
        let gameOverLabel = SKLabelNode(fontNamed: "Arial-Bold")
        gameOverLabel.text = "GAME OVER"
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: 0, y: 0)
        addChild(gameOverLabel)
        
        let restartLabel = SKLabelNode(fontNamed: "Arial")
        restartLabel.text = "Tap to restart"
        restartLabel.fontSize = 18
        restartLabel.fontColor = .white
        restartLabel.position = CGPoint(x: 0, y: -50)
        restartLabel.name = "restart"
        addChild(restartLabel)
    }
    
    private func restartGame() {
        // Remove all obstacles
        for obstacle in obstacles {
            obstacle.removeFromParent()
        }
        obstacles.removeAll()
        
        // Reset game state
        isGameOver = false
        score = 0
        currentLane = 1
        scoreLabel.text = "Score: 0"
        
        // Reset player position
        player.position = CGPoint(x: 0, y: -size.height/4)
        
        // Remove game over labels
        childNode(withName: "restart")?.removeFromParent()
        children.filter { $0 is SKLabelNode && ($0 as! SKLabelNode).text == "GAME OVER" }.forEach { $0.removeFromParent() }
        
        // Restart game loop
        startGameLoop()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        if isGameOver {
            if childNode(withName: "restart") != nil {
                restartGame()
            }
            return
        }
        
        // Determine which side of screen was tapped
        if location.x < 0 {
            // Left side - move left
            movePlayer(to: currentLane - 1)
        } else {
            // Right side - move right
            movePlayer(to: currentLane + 1)
        }
    }
}

// MARK: - Physics Contact Delegate
extension PerspectiveRunnerScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }
        
        // Check if player hit an obstacle
        if (contact.bodyA.categoryBitMask == 1 && contact.bodyB.categoryBitMask == 2) ||
           (contact.bodyA.categoryBitMask == 2 && contact.bodyB.categoryBitMask == 1) {
            gameOver()
        }
    }
}

// MARK: - SwiftUI Integration
struct PerspectiveRunnerGameView: View {
    
    var scene: SKScene {
        let scene = PerspectiveRunnerScene()
        // Use a large default size, but let SpriteView fill the available space
        scene.size = CGSize(width: 800, height: 1200)
        scene.scaleMode = .resizeFill
        scene.physicsWorld.contactDelegate = scene
        return scene
    }
    
    var body: some View {
        SpriteView(scene: scene)
//            .ignoresSafeArea()
//            .frame(maxWidth: .infinity, maxHeight: .infinity)
//            .navigationTitle("Perspective Runner")
//            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview
struct PerspectiveRunnerGameView_Previews: PreviewProvider {
    static var previews: some View {
        PerspectiveRunnerGameView()
    }
} 
