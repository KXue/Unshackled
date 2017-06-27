//
//  GameScene.swift
//  Unshackled
//
//  Created by Kevin Xue on 2017-06-20.
//  Copyright © 2017 Kevin Xue. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        attachTileMapPhysics(map: (childNode(withName: "Platforms") as! SKTileMapNode))
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    func attachTileMapPhysics(map: SKTileMapNode){
        
        let tileMap = map
        let tileSize = tileMap.tileSize
        let halfWidth = CGFloat(tileMap.numberOfColumns) / 2.0 * tileSize.width
        let halfHeight = CGFloat(tileMap.numberOfRows) / 2.0 * tileSize.height
        var physicsBodies = [SKPhysicsBody]()
        
        for col in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                if tileMap.tileDefinition(atColumn: col, row: row) != nil{
                    let x = CGFloat(col) * tileSize.width - halfWidth + (tileSize.width/2)
                    let y = CGFloat(row) * tileSize.height - halfHeight + (tileSize.height/2)
                    let body = SKPhysicsBody(rectangleOf: tileSize, center: CGPoint(x:x, y:y))
                    physicsBodies.append(body)
                }
            }
        }
        tileMap.physicsBody = SKPhysicsBody(bodies: physicsBodies)
        tileMap.physicsBody?.isDynamic = false
    }
}
