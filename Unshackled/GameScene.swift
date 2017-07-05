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
    
    //MARK Member Vars
    var mapNode: SKTileMapNode!
    var player: Player!
    var lastTime:TimeInterval = 0
    
    //MARK: Override Functions
    
    override func didMove(to view: SKView) {
        mapNode = childNode(withName: "Platforms") as! SKTileMapNode
        attachTileMapPhysics(map: mapNode)
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
        let deltaTime = lastTime > 0 ? currentTime - lastTime : 0
        lastTime = currentTime
        player.update(deltaTime)
    }
    
    //MARK: Gesture Recognizers
    
    func addGestureRecognizers(to view: SKView) {
        let leftSwipeRecognizer = UISwipeGestureRecognizer()
        let rightSwipeRecognizer = UISwipeGestureRecognizer()
        let downSwipeRecognizer = UISwipeGestureRecognizer()
        let upSwipeRecognizer = UISwipeGestureRecognizer()
        let tapRecognizer = UITapGestureRecognizer()
        
        leftSwipeRecognizer.addTarget(self, action: #selector(didSwipe(sender:)))
        leftSwipeRecognizer.direction = .left
        view.addGestureRecognizer(leftSwipeRecognizer)
        
        rightSwipeRecognizer.addTarget(self, action: #selector(didSwipe(sender:)))
        rightSwipeRecognizer.direction = .right
        view.addGestureRecognizer(rightSwipeRecognizer)

        downSwipeRecognizer.addTarget(self, action: #selector(didSwipe(sender:)))
        downSwipeRecognizer.direction = .down
        view.addGestureRecognizer(downSwipeRecognizer)
        
        upSwipeRecognizer.addTarget(self, action: #selector(didSwipe(sender:)))
        upSwipeRecognizer.direction = .up
        view.addGestureRecognizer(upSwipeRecognizer)
        
        tapRecognizer.addTarget(self, action: #selector(didTap(sender:)))
        view.addGestureRecognizer(tapRecognizer)
    }
    
    func removeGestureRecognizers() {
        for gesture in (view?.gestureRecognizers)!{
            view?.removeGestureRecognizer(gesture)
        }
    }
    
    //MARK: Gesture Handlers
    
    func didSwipe(sender:UISwipeGestureRecognizer){
        switch sender.direction{
        case UISwipeGestureRecognizerDirection.left:
            player.startRunning(isRight: false)
        case UISwipeGestureRecognizerDirection.right:
            player.startRunning(isRight: true)
        case UISwipeGestureRecognizerDirection.up:
            player.startJumping()
        case UISwipeGestureRecognizerDirection.down:
            player.stop()
        default:
            break
        }
    }
    
    func didTap(sender: UITapGestureRecognizer){
        let touchLocation = convertPoint(fromView: sender.location(in: sender.view))
        print("\(convertPoint(fromView: sender.location(in: sender.view)))")
        print("\(player.position)")
        player.shoot(at: CGPoint(x: touchLocation.x - player.position.x, y: touchLocation.y - player.position.y))
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
        var physicsBodies = [SKPhysicsBody]()
        var start:Int = -1
        var end:Int = -1
        var isTop = false
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
                            isTop = tileDefinition.name!.range(of:"TilesT") != nil
                            
                        }else{
                            let x = CGFloat(col) * tileSize.width - halfWidth + (tileSize.width * 0.5)
                            let y = CGFloat(row) * tileSize.height - halfHeight + (tileSize.height * 0.5)
                            physicsBodies.append(SKPhysicsBody(rectangleOf: tileSize, center: CGPoint(x:x, y:y)))
                            start = -1
                            end = -1
                        }
                    } else if start != -1 {
                        physicsBodies.append(createRowTiles(start: start, end: end, row: row, tileSize: tileSize, halfSize:CGSize(width: halfWidth, height: halfHeight),fractionSize: topBottomTileSize, isTop: isTop))
                        start = -1
                        end = -1
                    }
                }else if start != -1 {
                    //make rectangle here
                    physicsBodies.append(createRowTiles(start: start, end: end, row: row, tileSize: tileSize, halfSize:CGSize(width: halfWidth, height: halfHeight),fractionSize: topBottomTileSize, isTop: isTop))
                    start = -1
                    end = -1
                }
            }
            if start != -1{
                physicsBodies.append(createRowTiles(start: start, end: end, row: row, tileSize: tileSize, halfSize:CGSize(width: halfWidth, height: halfHeight),fractionSize: topBottomTileSize, isTop: isTop))
                start = -1
                end = -1
            }
        }
        tileMap.physicsBody = SKPhysicsBody(bodies: physicsBodies)
        tileMap.physicsBody?.isDynamic = false
        tileMap.physicsBody?.friction = 0
        tileMap.physicsBody?.linearDamping = 0
        tileMap.physicsBody?.categoryBitMask = PhysicsCategory.Platform
        tileMap.physicsBody?.collisionBitMask = PhysicsCategory.Player
        tileMap.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        tileMap.physicsBody?.fieldBitMask = PhysicsCategory.None
    }
//     body = SKPhysicsBody(rectangleOf: topBottomTileSize, center: CGPoint(x:x, y: y + topBottomOffset))
    func createRowTiles(start: Int, end: Int, row: Int, tileSize: CGSize, halfSize: CGSize, fractionSize: CGSize, isTop: Bool) -> SKPhysicsBody {
        let topBottomOffset = CGFloat((tileSize.height - fractionSize.height) * 0.5) * (isTop ? -1 : 1)
        let position = CGPoint(
            x: CGFloat(Double(end) - Double(end - start) * 0.5) * tileSize.width - halfSize.width + (tileSize.width * 0.5),
            y: CGFloat(row) * tileSize.height - halfSize.height + (tileSize.height * 0.5) + topBottomOffset)
        let size = CGSize(width: CGFloat(end - start + 1) * tileSize.width, height: fractionSize.height)
        return SKPhysicsBody(rectangleOf: size, center: position)
    }
}
