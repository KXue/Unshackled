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
    static let Platform: UInt32          = 0b10
}

class GameScene: SKScene {
    //MARK: Member Lets
    let topBottomTileReductionFraction:CGFloat = 0.55
    let panRecognizer = UIPanGestureRecognizer()
    
    //MARK Member Vars
    var player: Player!
    var panAmount: CGFloat = 0

    
    //MARK: Override Functions
    
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
        player = childNode(withName: "Player") as! Player
        addGestureRecognizers(to: view)
    }
    
    override func update(_ currentTime: TimeInterval) {
        player.move(amount: panAmount)
    }
    
    //MARK: Gesture Recognizers
    
    func addGestureRecognizers(to view: SKView) {
        panRecognizer.addTarget(self, action: #selector(didPan(sender:)))
        view.addGestureRecognizer(panRecognizer)
    }
    
    func removeGestureRecognizers() {
        for gesture in (view?.gestureRecognizers)!{
            view?.removeGestureRecognizer(gesture)
        }
    }
    
    //MARK: Gesture Handlers
    
    func didPan(sender: UIPanGestureRecognizer){
        if sender.state != .ended {
            panAmount = sender.translation(in: view).x
        }else{
            panAmount = 0
        }
    }
    
    //MARK: TileMap Physics
    
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
    
    func attachTileMapPhysics(map: SKTileMapNode){
        let tileMap = map
        let tileSize = tileMap.tileSize
        let halfWidth = CGFloat(tileMap.numberOfColumns) * 0.5 * tileSize.width
        let halfHeight = CGFloat(tileMap.numberOfRows) * 0.5 * tileSize.height
        let topBottomTileSize = CGSize(width: tileSize.width, height: tileSize.height * topBottomTileReductionFraction)
        let topBottomOffset = (tileSize.height - topBottomTileSize.height) * 0.5
        
        var physicsBodies = [SKPhysicsBody]()
        
        var start:Int = -1
        var end:Int = -1
        for row in 0..<tileMap.numberOfRows {
            
            for col in 0..<tileMap.numberOfColumns {
                if let tileDefinition = tileMap.tileDefinition(atColumn: col, row: row){
                    if tileDefinition.name!.range(of: "C") == nil{
                        if tileDefinition.name!.range(of:"TilesT") != nil  || tileDefinition.name!.range(of:"TilesB") != nil {
                            if start == -1 {
                                start = col
                                end = col
                            }
                            else{
                                end = col
                            }
                            
                        }else{
                            let x = CGFloat(col) * tileSize.width - halfWidth + (tileSize.width * 0.5)
                            let y = CGFloat(row) * tileSize.height - halfHeight + (tileSize.height * 0.5)
                            physicsBodies.append(SKPhysicsBody(rectangleOf: tileSize, center: CGPoint(x:x, y:y)))
                            start = -1
                            end = -1
                        }
                    } else if start != -1 {
                        physicsBodies.append(createRowTiles(start: start, end: end, row: row, tileSize: tileSize, halfSize:CGSize(width: halfWidth, height: halfHeight)))
                        start = -1
                        end = -1
                    }
                }else if start != -1 {
                    //make rectangle here
                    physicsBodies.append(createRowTiles(start: start, end: end, row: row, tileSize: tileSize, halfSize:CGSize(width: halfWidth, height: halfHeight)))
                    start = -1
                    end = -1
                }
            }
            if start != -1{
                physicsBodies.append(createRowTiles(start: start, end: end, row: row, tileSize: tileSize, halfSize:CGSize(width: halfWidth, height: halfHeight)))
                start = -1
                end = -1
            }
        }
        tileMap.physicsBody = SKPhysicsBody(bodies: physicsBodies)
        tileMap.physicsBody?.isDynamic = false
        tileMap.physicsBody?.categoryBitMask = PhysicsCategory.Platform
        tileMap.physicsBody?.collisionBitMask = PhysicsCategory.Player
        tileMap.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        tileMap.physicsBody?.fieldBitMask = PhysicsCategory.None
    }
//     body = SKPhysicsBody(rectangleOf: topBottomTileSize, center: CGPoint(x:x, y: y + topBottomOffset))
    func createRowTiles(start: Int, end: Int, row: Int, tileSize: CGSize, halfSize: CGSize) -> SKPhysicsBody {
        let position = CGPoint(
            x: CGFloat(Double(end) - Double(end - start) * 0.5) * tileSize.width - halfSize.width + (tileSize.width * 0.5),
            y: CGFloat(row) * tileSize.height - halfSize.height + (tileSize.height * 0.5))
        let size = CGSize(width: CGFloat(end - start + 1) * tileSize.width, height: tileSize.height)
        return SKPhysicsBody(rectangleOf: size, center: position)
    }
}
