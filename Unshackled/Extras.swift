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
    func createAnimations(frameTime: TimeInterval)
}

extension Animatable {
    func setupAnimationWithPrefix(_ prefix: String, start: UInt, end: UInt, timePerFrame: TimeInterval) -> SKAction {
        var textures = [SKTexture]()
        for i in start...end {
            textures.append(SKTexture(pixelImageNamed: "\(prefix)\(i)"))
        }
        return SKAction.animate(with: textures, timePerFrame: timePerFrame)
    }
}

protocol EventListenerNode{
    func didMoveToScene()
}

extension SKTexture{
    convenience init(pixelImageNamed: String){
        self.init(imageNamed: pixelImageNamed)
        self.filteringMode = .nearest
    }
}

