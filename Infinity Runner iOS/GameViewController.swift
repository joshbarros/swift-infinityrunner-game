//
//  GameViewController.swift
//  Infinity Runner iOS
//
//  Created by Josue Barros on 08/12/24.
//

import UIKit
import SpriteKit
import GameplayKit

class GameViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Create the game scene
            let scene = GameScene(size: view.bounds.size)
            
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .resizeFill
            
            // Configure the view
            view.ignoresSiblingOrder = true
            view.showsFPS = true  // Useful for debugging
            view.showsNodeCount = true  // Useful for debugging
            
            // Present the scene
            view.presentScene(scene)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
