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
    var box: SKShapeNode? = nil
    let topScale: CGFloat = 0.3
    let bottomScale: CGFloat = 1.5
    var currentLaneIndex: Int = 0
    var currentBoxY: CGFloat = 0
    
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
                let newRect = CGRect(x: -width/2, y: -50, width: width, height: baseHeight * scale)
                box!.path = CGPath(rect: newRect, transform: nil)
                
                box!.position = CGPoint(x: widthX1 + width / 2, y: currentBoxY + 50)
                if box!.position.y < 0 - (baseHeight * scale){
                    box!.removeFromParent()
                    box = nil
                    currentBoxY = size.height - size.height / 3
                    currentLaneIndex = Int.random(in: 0..<numberOfLanes - 1)
                }
            } else {
                let scale = calculateScale(forY: currentBoxY)
                let newBox = SKShapeNode(rectOf: CGSize(width: width, height: baseHeight * scale))
                newBox.alpha = 0
                newBox.run(
                    SKAction.fadeAlpha(to: 1, duration: 0.5)
                )
                newBox.fillColor = .white
                newBox.position = CGPoint(x: widthX1 + width / 2, y: currentBoxY + baseHeight * scale / 2)
                box = newBox
                addChild(newBox)
            }
            currentBoxY -= 6 * calculateScale(forY: currentBoxY)
  
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
}


struct TheTilesView: View {
    var scene: SKScene {
        let scene = TheTiles()
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.scaleMode = .resizeFill
        return scene
    }
    
    var body: some View {
        SpriteView(scene: scene)
            .ignoresSafeArea()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Perspective Runner")
            .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    TheTilesView()
}

