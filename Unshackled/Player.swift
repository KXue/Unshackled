//
//  Player.swift
//  Unshackled
//
//  Created by Kevin Xue on 2017-06-25.
//  Copyright © 2017 Kevin Xue. All rights reserved.
//

import SpriteKit

enum PlayerAnimation: Int{
    case idle, run, jumpUp, jumpDown, crouch, shoot, end
}

class Player: SKSpriteNode, EventListenerNode, Animatable {
    let animationFrameStart: [UInt] = [1, 1, 1, 5, 1, 1]
    let animationFrameEnd: [UInt] = [5, 10, 5, 9, 2, 2]
    let animationName: [String] = ["Idle", "Run", "Jump", "Jump", "Crouch", "Shoot"]
    let animationRepeats: [Bool] = [true, true, false, false, false, false]
    let physicsSize = CGSize(width: 8.0, height: 16.0)
    let playerRadius: CGFloat = 8.0
    let movementSpeed: CGFloat = 150.0
    let jumpSpeed: CGFloat = 400.0
    
    var numBullets: UInt = 3
    var maxBullets: UInt = 3
    var gunNode: SKNode!
    var animations = [SKAction]()
    var currentAnimation: SKAction?
    var direction: CGFloat = 0
    var currentAction: PlayerAnimation = .idle
    
    func createAnimations(frameTime: TimeInterval){
        for animation in 0..<PlayerAnimation.end.rawValue{
            let animationAction: SKAction = setupAnimationWithPrefix(animationName[animation], start: animationFrameStart[animation], end: animationFrameEnd[animation], timePerFrame: frameTime)
            if(animationRepeats[animation]){
                animations.append(SKAction.repeatForever(animationAction))
            } else {
                animations.append(animationAction)
            }
        }
    }
    
    func createDeathAnimation(viewHeight: CGFloat) -> SKAction{
        let deathAnimationUp = SKAction.moveBy(x: 0, y: viewHeight * 0.3, duration: 0.3)
        deathAnimationUp.timingMode = .easeOut
        let deathAnimationDown = SKAction.moveBy(x: 0, y: -viewHeight, duration: 0.9)
        deathAnimationDown.timingMode = .easeIn
        return SKAction.sequence([deathAnimationUp, deathAnimationDown])
    }
    
    func didMoveToScene(){
        gunNode = childNode(withName: "GunNode")!
        setupPhysics()
    }
    
    func increaseAmmo(by amount: UInt){
        maxBullets += amount
        numBullets += amount
    }
    
    func playAnimation(_ animationIndex: PlayerAnimation){
        if animationIndex != .end {
            let animation = animations[animationIndex.rawValue]
            if currentAnimation == nil || currentAnimation != animation{
                run(animation, withKey: "animation")
                currentAnimation = animation
            }
        }
    }
    
    func resetBullets(){
        numBullets = maxBullets
    }
    
    func setupPhysics(){
        physicsBody = SKPhysicsBody(rectangleOf: physicsSize, center: childNode(withName: "PhysicsCenter")!.position)
        physicsBody?.allowsRotation = false
        physicsBody?.collisionBitMask = PhysicsCategory.Platform | PhysicsCategory.Edge
        physicsBody?.fieldBitMask = PhysicsCategory.Platform | PhysicsCategory.Edge
        physicsBody?.categoryBitMask = PhysicsCategory.Player
        physicsBody?.contactTestBitMask = PhysicsCategory.Platform | PhysicsCategory.Edge | PhysicsCategory.Goal
        physicsBody?.friction = 0.0
        physicsBody?.linearDamping = 0.1
        physicsBody?.restitution = 0
    }
    
    func startRunning(isRight: Bool){
        direction = (isRight ? 1 : -1)
        physicsBody?.velocity = CGVector(dx: movementSpeed * direction, dy: (physicsBody?.velocity.dy)!)
        xScale = direction
        if currentAction == .idle{
            currentAction = .run
        }
    }
    
    func startJumping() -> Bool{
        var retVal = false
        if currentAction != .jumpUp && currentAction != .jumpDown{
            physicsBody?.velocity = CGVector(dx: (physicsBody?.velocity.dx)!, dy: jumpSpeed)
            currentAction = .jumpUp
            retVal = true
        }
        return retVal
    }
    
    func stop(){
        direction = 0
        physicsBody?.velocity = CGVector(dx: 0, dy: (physicsBody?.velocity.dy)!)
        currentAction = .idle
    }
    
    func shoot(at direction: CGVector){
        if numBullets != 0 {
            let angle = atan2(direction.dy, direction.dx)
            let spriteAngle: CGFloat?
            
            if abs(angle) > CGFloat(Double.pi * 0.5) {
                xScale = -1
                spriteAngle = (angle < 0 ? 1 : -1) * CGFloat(Double.pi) + angle
            }
            else{
                xScale = 1
                spriteAngle = angle
            }
            
            self.currentAction = .shoot
            
            let resetAction = SKAction.run(){
                self.currentAction = .jumpDown
            }
            
            let rotateAction = SKAction.rotate(byAngle: spriteAngle!, duration: TimeInterval(abs(CGFloat(0.04) * spriteAngle!)))
            let reverseRotateAction = rotateAction.reversed()
            
            let recoilMagnitude:CGFloat = -2.0
            let recoilVector = CGVector(dx: cos(angle) * recoilMagnitude, dy: sin(angle) * recoilMagnitude)
            
            let shootBullet = SKAction.run(){
                self.playAnimation(.shoot)
                (self.parent as! GameScene).spawnBullet(at: self.convert(self.gunNode.position, to: self.parent!), angle: angle)
                self.physicsBody?.applyImpulse(recoilVector)
            }
            
            let rotateSequence = SKAction.sequence([
                rotateAction, shootBullet, reverseRotateAction, resetAction])
            
            run(rotateSequence);
            numBullets -= 1
        }
    }
    
    func update(_ deltaTime: TimeInterval){
        updatePlayerState()
    }
    
    func updatePlayerState(){
        if direction != 0 && physicsBody?.velocity.dx != direction * movementSpeed{
            physicsBody?.velocity.dx = direction * movementSpeed
        }
        
        if currentAction == .jumpDown && physicsBody?.velocity.dy == 0 {
            currentAction = .idle
        } else if currentAction == .jumpUp && (physicsBody?.velocity.dy)! < CGFloat(0) {
            currentAction = .jumpDown
        }
        
        if currentAction == .idle && physicsBody?.velocity.dx != 0 {
            currentAction = .run
        }
        
        playAnimation(currentAction)
    }
}
