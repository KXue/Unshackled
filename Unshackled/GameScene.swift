//
//  GameScene.swift
//  Unshackled
//
//  Created by Kevin Xue on 2017-06-20.
//  Copyright © 2017 Kevin Xue. All rights reserved.
//

import SpriteKit
import GameplayKit

struct PhysicsCategory{
    static let None: UInt32              = 0b0
    static let Player: UInt32            = 0b1
    static let Platform: UInt32    = 0b10
}

class GameScene: SKScene {
    
    override func didMove(to view: SKView) {
        attachTileMapPhysics(map: (childNode(withName: "Platforms") as! SKTileMapNode))
        enumerateChildNodes(withName: "//*", using: {node, _ in
            if let animatableNode = node as? Animatable{
                animatableNode.createAnimations(frameTime: 1.0/10.0)
            }
            if let eventListenerNode = node as? EventListenerNode{
                eventListenerNode.didMoveToScene()
            }
        })
    }
    
    override func update(_ currentTime: TimeInterval) {
        
    }
    
    func attachTileMapPhysics(map: SKTileMapNode){
        let tileMap = map
        let tileSize = tileMap.tileSize
        let halfWidth = CGFloat(tileMap.numberOfColumns) * 0.5 * tileSize.width
        let halfHeight = CGFloat(tileMap.numberOfRows) * 0.5 * tileSize.height
        var physicsBodies = [SKPhysicsBody]()
        
        for col in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row){
                    if tileDefinition.name!.range(of: "C") == nil{
                        let x = CGFloat(col) * tileSize.width - halfWidth + (tileSize.width * 0.5)
                        let y = CGFloat(row) * tileSize.height - halfHeight + (tileSize.height * 0.5)
                        let body = SKPhysicsBody(rectangleOf: tileSize, center: CGPoint(x:x, y:y))
                        physicsBodies.append(body)
                    }
                }
            }
        }
        tileMap.physicsBody = SKPhysicsBody(bodies: physicsBodies)
        tileMap.physicsBody?.isDynamic = false
        tileMap.physicsBody?.categoryBitMask = PhysicsCategory.Platform
        tileMap.physicsBody?.collisionBitMask = PhysicsCategory.Player
        tileMap.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        tileMap.physicsBody?.fieldBitMask = PhysicsCategory.None
    }
    
    func alternateTileMapPhysics(map: SKTileMapNode){
        let tileMap = map
        let tileSize = tileMap.tileSize
        let halfWidth = CGFloat(tileMap.numberOfColumns) * 0.5 * tileSize.width
        let halfHeight = CGFloat(tileMap.numberOfRows) * 0.5 * tileSize.height
        
        for col in 0..<tileMap.numberOfColumns {
            for row in 0..<tileMap.numberOfRows {
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row) {
                    if tileDefinition.name!.range(of: "C") == nil{
                        let x = CGFloat(col) * tileSize.width - halfWidth + (tileSize.width * 0.5)
                        let y = CGFloat(row) * tileSize.height - halfHeight + (tileSize.height * 0.5)
                        let tileNode = SKNode()
                        tileNode.position = CGPoint(x: x, y: y)
                        tileNode.physicsBody = SKPhysicsBody(rectangleOf: tileSize)
                        
                        tileNode.physicsBody?.isDynamic = false
                        tileNode.physicsBody?.categoryBitMask = PhysicsCategory.Platform
                        tileNode.physicsBody?.collisionBitMask = PhysicsCategory.Player
                        tileNode.physicsBody?.contactTestBitMask = PhysicsCategory.Player
                        tileNode.physicsBody?.fieldBitMask = PhysicsCategory.None
                        
                        tileNode.yScale = tileMap.yScale
                        tileNode.xScale = tileMap.xScale
                        tileMap.addChild(tileNode)
                    }
                }
            }
        }
    }
}
