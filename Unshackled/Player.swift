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
                animation = SKAction.sequence([animations[animationIndex.rawValue] , animations[PlayerAnimation.idle.rawValue]])
            }
            run(animation, withKey: "animation")
        }

    }
    
    func didMoveToScene(){
        playAnimation(animationIndex: PlayerAnimation.run)
    }
    
    func setupPhysics(){
        
    }
}
