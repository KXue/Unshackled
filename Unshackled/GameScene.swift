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
    static let None: UInt32             = 0b0
    static let Player: UInt32           = 0b1
    static let Platform: UInt32         = 0b10
    static let Bullet: UInt32           = 0b100
    static let Edge: UInt32             = 0b1000
    static let Ammo: UInt32             = 0b10000
    static let Goal: UInt32             = 0b100000
    static let All: UInt32              = UInt32.max
}

class GameScene: SKScene {
    //MARK: Member Lets
    let topBottomTileReductionFraction:CGFloat = 0.55
    
    //MARK Member Vars
    var goalNode: SKSpriteNode!
    var mapNode: SKTileMapNode!
    var visibleSize: CGSize!
    var player: Player!
    var sourceBullet: Bullet!
    var lastTime:TimeInterval = 0
    
    //MARK: Override Functions
    
    override func didMove(to view: SKView) {
        setupVisibleSize()
        setupTextureFilter()
        
        backgroundColor = UIColor(colorLiteralRed: 0.318, green: 0.659, blue: 1.0, alpha: 1.0)
        physicsWorld.gravity.dy *= 0.75
        
        mapNode = childNode(withName: "Platforms") as! SKTileMapNode
        setupPhysics()
        
        sourceBullet = SKScene(fileNamed: "Bullet")!.childNode(withName: "Bullet") as! Bullet
        sourceBullet.texture?.filteringMode = .nearest
        
        enumerateChildNodes(withName: "//*", using: {node, _ in
            if let animatableNode = node as? Animatable{
                animatableNode.createAnimations(frameTime: 1.0/12.0)
            }
            if let eventListenerNode = node as? EventListenerNode{
                eventListenerNode.didMoveToScene()
            }
        })
        
        player = childNode(withName: "Player") as! Player
        goalNode = childNode(withName: "Goal") as! SKSpriteNode
        setupGoal(goalNode)
        
        addGestureRecognizers(to: view)
        setupCamera()
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
        player.shoot(at: CGVector(dx: touchLocation.x - player.position.x, dy: touchLocation.y - player.position.y))
    }
    
    //MARK: Setup Functions
    
    func setupCamera(){
        guard let camera = camera else {return}
        
        let bufferedDistance = SKRange(value: 0, variance: 20)
        let playerConstraint = SKConstraint.distance(bufferedDistance, to:player)
        
        let xInset = min(visibleSize.width * 0.5, mapNode.frame.width * 0.5)
        let yInset = min(visibleSize.height * 0.5, mapNode.frame.height * 0.5)
        let constraintRect = mapNode.frame.insetBy(dx: xInset, dy: yInset)
        let xRange = SKRange(lowerLimit: constraintRect.minX,
                             upperLimit: constraintRect.maxX)
        let yRange = SKRange(lowerLimit: constraintRect.minY,
                             upperLimit: constraintRect.maxY)
        let edgeConstraint = SKConstraint.positionX(xRange, y: yRange)
        edgeConstraint.referenceNode = mapNode
        
        camera.constraints = [playerConstraint, edgeConstraint]
    }
    
    func setupGoal(_ goal: SKSpriteNode){
        goal.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        goal.physicsBody?.categoryBitMask = PhysicsCategory.Goal
        goal.physicsBody?.fieldBitMask = PhysicsCategory.None
        goal.physicsBody?.collisionBitMask = PhysicsCategory.None
    }
    
    func setupPhysics(){
        mapNode.physicsBody = SKPhysicsBody(edgeLoopFrom: mapNode.frame)
        mapNode.physicsBody?.categoryBitMask = PhysicsCategory.Edge
        mapNode.physicsBody?.friction = 0.0
        physicsWorld.contactDelegate = self
        attachTileMapPhysics(map: mapNode)
    }
    
    func setupTextureFilter(){
        enumerateChildNodes(withName: "//*", using: {node, _ in
            if let spriteNode = node as? SKSpriteNode{
                spriteNode.texture?.filteringMode = .nearest
            }
        })
    }
    
    func setupVisibleSize(){
        let aspectRatio = size.width / size.height
        let viewRatio = view!.frame.width / view!.frame.height
        
        if(aspectRatio < viewRatio){
            let width = size.width
            let height = width / viewRatio
            visibleSize = CGSize(width: width * camera!.xScale, height: height * camera!.yScale)
        }
        else{
            let height = size.height
            let width = height * viewRatio
            visibleSize = CGSize(width: width * camera!.xScale, height: height * camera!.yScale)
        }
    }
    
    //MARK: TileMap Physics
    
    func attachTileMapPhysics(map: SKTileMapNode){
        let worldPhysicsNode = SKNode()
        worldPhysicsNode.position = CGPoint(x:0, y:0)
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
        worldPhysicsNode.physicsBody = SKPhysicsBody(bodies: physicsBodies)
        worldPhysicsNode.physicsBody?.isDynamic = false
        worldPhysicsNode.physicsBody?.friction = 0.0
        worldPhysicsNode.physicsBody?.restitution = 0.0
        worldPhysicsNode.physicsBody?.linearDamping = 0
        worldPhysicsNode.physicsBody?.categoryBitMask = PhysicsCategory.Platform
        worldPhysicsNode.physicsBody?.collisionBitMask = PhysicsCategory.Player
        worldPhysicsNode.physicsBody?.contactTestBitMask = PhysicsCategory.Player
        worldPhysicsNode.physicsBody?.fieldBitMask = PhysicsCategory.None
        map.addChild(worldPhysicsNode)
    }

    func createRowTiles(start: Int, end: Int, row: Int, tileSize: CGSize, halfSize: CGSize, fractionSize: CGSize, isTop: Bool) -> SKPhysicsBody {
        let topBottomOffset = CGFloat((tileSize.height - fractionSize.height) * 0.5) * (isTop ? -1 : 1)
        let position = CGPoint(
            x: CGFloat(Double(end) - Double(end - start) * 0.5) * tileSize.width - halfSize.width + (tileSize.width * 0.5),
            y: CGFloat(row) * tileSize.height - halfSize.height + (tileSize.height * 0.5) + topBottomOffset)
        let size = CGSize(width: CGFloat(end - start + 1) * tileSize.width, height: fractionSize.height)
        return SKPhysicsBody(rectangleOf: size, center: position)
    }
    
    //MARK: Misc Functions
    
    func spawnBullet(at position: CGPoint, angle: CGFloat){
        let bullet = sourceBullet.copy() as! Bullet
        bullet.didMoveToScene()
        bullet.createAnimations(frameTime: 0.02)
        bullet.position = position
        bullet.zRotation = angle
        bullet.setVelocity(angle: angle)
        addChild(bullet)
    }
    
    func winLevel(){
        
    }
}
extension GameScene : SKPhysicsContactDelegate{
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.categoryBitMask == PhysicsCategory.Bullet || contact.bodyB.categoryBitMask == PhysicsCategory.Bullet{
            let bullet = contact.bodyA.categoryBitMask == PhysicsCategory.Bullet ? (contact.bodyA.node as! Bullet) : (contact.bodyB.node as! Bullet)
            bullet.onHit()
        }
        if contact.bodyA.categoryBitMask == PhysicsCategory.Player || contact.bodyB.categoryBitMask == PhysicsCategory.Player{
            let other = contact.bodyA.categoryBitMask == PhysicsCategory.Player ? contact.bodyB : contact.bodyA
            switch other.categoryBitMask {
            case PhysicsCategory.Platform:
                player.resetBullets()
            case PhysicsCategory.Edge:
                player.resetBullets()
            case PhysicsCategory.Goal:
                winLevel()
            case PhysicsCategory.Ammo:
                player.increaseAmmo(by: 1)
            default:
                break
            }
        }
    }
}
