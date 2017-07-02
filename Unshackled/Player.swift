//
//  Player.swift
//  Unshackled
//
//  Created by Kevin Xue on 2017-06-25.
//  Copyright © 2017 Kevin Xue. All rights reserved.
//

import SpriteKit

enum PlayerAnimation: Int{
    case run = 0, idle, jumpUp, jumpDown, crouch, shoot, end
}

class Player: SKSpriteNode, EventListenerNode, Animatable {
    let animationFrameStart: [UInt] = [1, 1, 1, 5, 1, 1]
    let animationFrameEnd: [UInt] = [10, 5, 5, 9, 2, 2]
    let animationName: [String] = ["Run", "Idle", "Jump", "Jump", "Crouch", "Shoot"]
    let animationRepeats: [Bool] = [true, true, false, false, false, false]
    let playerRadius: CGFloat = 8.0
    let movementSpeed: CGFloat = 8.0
    
    var footNode: SKNode!
    var animations = [SKAction]()
    
    
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
    
    func playAnimation(animationIndex: PlayerAnimation){
        var animation: SKAction!
        if(animationIndex != .end){
            if animationRepeats[animationIndex.rawValue]{
                animation = animations[animationIndex.rawValue]
            } else {
//                animation = SKAction.sequence([animations[animationIndex.rawValue] , animations[PlayerAnimation.idle.rawValue]])
                animation = SKAction.repeatForever(animations[animationIndex.rawValue])
            }
            run(animation, withKey: "animation")
        }

    }
    
    func didMoveToScene(){
        footNode = childNode(withName: "FootNode")!
        setupPhysics()
        playAnimation(animationIndex: PlayerAnimation.idle)
    }
    
    func move(amount: CGFloat){
        let normalizedAmount = abs(amount) > 1 ? amount / abs(amount) : amount
        physicsBody?.applyForce(CGVector(dx: normalizedAmount * movementSpeed, dy: (physicsBody?.velocity.dy)!))
        
    }
    
    func setupPhysics(){
        physicsBody = SKPhysicsBody(circleOfRadius: playerRadius)
        physicsBody?.allowsRotation = false
        physicsBody?.collisionBitMask = PhysicsCategory.Platform
        physicsBody?.fieldBitMask = PhysicsCategory.Platform
        physicsBody?.categoryBitMask = PhysicsCategory.Player
        physicsBody?.friction = 0
        physicsBody?.linearDamping = 0
        physicsBody?.restitution = 0
        
        footNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 8, height: 8))
        footNode.physicsBody?.allowsRotation = false
        footNode.physicsBody?.collisionBitMask = PhysicsCategory.Platform
        footNode.physicsBody?.fieldBitMask = PhysicsCategory.Platform
        footNode.physicsBody?.categoryBitMask = PhysicsCategory.Player
        footNode.physicsBody?.pinned = true
        footNode.physicsBody?.friction = 0
        footNode.physicsBody?.linearDamping = 0
        footNode.physicsBody?.restitution = 0

    }
}
