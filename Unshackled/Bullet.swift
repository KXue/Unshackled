//
//  Bullet.swift
//  Unshackled
//
//  Created by Kevin Xue on 2017-07-06.
//  Copyright © 2017 Kevin Xue. All rights reserved.
//

import SpriteKit

class Bullet: SKSpriteNode, EventListenerNode, Animatable{
    var animations = [SKAction]()
    var currentAnimation: SKAction?
    let travelSpeed: CGFloat = 250.0
    let lifeTime:TimeInterval = 15.0

    func didMoveToScene(){
        setupPhysics()
        
        // destroy self after some time
        run(SKAction.sequence([SKAction.wait(forDuration: lifeTime), SKAction.removeFromParent()]))
    }
    func createAnimations(frameTime: TimeInterval){
        let stopAction = SKAction.run(){self.physicsBody?.velocity = CGVector.zero}
        animations.append(SKAction.sequence([stopAction, setupAnimationWithPrefix("Bullet", start: 1, end: 7, timePerFrame: frameTime), SKAction.run(){[weak self] in self?.removeFromParent()}]))
    }
    func setupPhysics(){
        physicsBody?.contactTestBitMask = UInt32.max
        physicsBody?.categoryBitMask = PhysicsCategory.Bullet
        physicsBody?.fieldBitMask = PhysicsCategory.None
        physicsBody?.collisionBitMask = PhysicsCategory.None
    }
    func setVelocity(angle: CGFloat){
        let y = sin(angle)
        let x = cos(angle)
        physicsBody?.velocity = CGVector(dx: x * travelSpeed, dy: y * travelSpeed)
    }
    func onHit(){
        let animation = animations[0]
        if currentAnimation == nil || currentAnimation != animation{
            run(animation, withKey: "animation")
            currentAnimation = animation
        }
    }
}
