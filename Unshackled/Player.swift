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
    let playerRadius: CGFloat = 8.0
    let movementSpeed: CGFloat = 60.0
    let jumpSpeed: CGFloat = 400.0
    
    var footNode: SKNode!
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
    
    func didMoveToScene(){
        footNode = childNode(withName: "FootNode")!
        setupPhysics()
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
    
    func setupPhysics(){
        physicsBody = SKPhysicsBody(bodies:
            [SKPhysicsBody(circleOfRadius: playerRadius),
             SKPhysicsBody(rectangleOf: CGSize(width: 9, height: 9), center: (childNode(withName: "FootNode")!).position)])
        physicsBody?.allowsRotation = false
        physicsBody?.collisionBitMask = PhysicsCategory.Platform
        physicsBody?.fieldBitMask = PhysicsCategory.Platform
        physicsBody?.categoryBitMask = PhysicsCategory.Player
        physicsBody?.friction = 0
        physicsBody?.linearDamping = 0
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
    
    func startJumping(){
        if currentAction != .jumpUp && currentAction != .jumpDown{
            physicsBody?.velocity = CGVector(dx: (physicsBody?.velocity.dx)!, dy: jumpSpeed)
            currentAction = .jumpUp
        }
    }
    
    func stop(){
        direction = 0
        physicsBody?.velocity = CGVector(dx: 0, dy: (physicsBody?.velocity.dy)!)
        if currentAction == .run {
            currentAction = .idle
        }

    }
    
    func shoot(at location: CGPoint){
        let angle = atan2(location.y, location.x)
        print("\(location)")
        print("\(angle)")
        let turnAction = SKAction.run(){
            self.currentAction = .shoot
            self.zRotation = angle
            self.playAnimation(.shoot)
        }
//        let returnAction = SKAction.run(){
//            self.zRotation = 0
//            self.currentAction = .idle
//        }
//        
//        let shootAction = SKAction.sequence([turnAction, returnAction])
        run(turnAction);
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
