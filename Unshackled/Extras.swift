//
//  Extensions.swift
//  Unshackled
//
//  Created by Kevin Xue on 2017-06-25.
//  Copyright © 2017 Kevin Xue. All rights reserved.
//

import SpriteKit

protocol Animatable: class{
    var animations: [SKAction] {get set}
    func createAnimations(frameTime: CGFloat)
}

extension Animatable{
    func animationDirection(for directionVector: CGVector) -> Direction{
        let direction: Direction
        if abs(directionVector.dy) > abs(directionVector.dx){
            direction = directionVector.dy < 0 ? .forward : .backward
        } else {
            direction = directionVector.dx < 0 ? .left : .right
        }
        return direction
    }
}

protocol EventListenerNode{
    func didMoveToScene()
}

