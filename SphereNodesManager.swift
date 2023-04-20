//
//  SphereNodesManager.swift
//  AR Drawing
//
//  Created by Thanphicha Yimlamai on 25/2/2566 BE.
//

import SceneKit

enum StrokeColor: String {
    case red = "red"
    case green = "green"
    case blue = "blue"
    case white = "white"
    case black = "black"
    case yellow = "yellow"
}

class SphereNodesManager {

    private let defaultSphereRadius: CGFloat = 0.004

    // Creating thousands of nodes uses up a lot of memory so instead we use cloning. Reference spheres are created once and then cloned instead of creating new spheres every time.
    private lazy var redReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.red)
    }()

    private lazy var greenReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.green)
    }()

    private lazy var blueReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.blue)
    }()

    private lazy var whiteReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.white)
    }()

    private lazy var blackReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.black)
    }()

    private lazy var yellowReferenceSphereNode: SCNNode = {
        return createSphereNode(color: UIColor.yellow)
    }()
    
    private func createSphereNode(color: UIColor) -> SCNNode {
        let sphere = SCNSphere(radius: defaultSphereRadius)
        sphere.firstMaterial?.diffuse.contents = color
        return SCNNode(geometry: sphere)
    }

    func getReferenceSphereNode(forStrokeColor color: StrokeColor) -> SCNNode {
        switch color {
        case .red:
            return redReferenceSphereNode
        case .green:
            return greenReferenceSphereNode
        case .blue:
            return blueReferenceSphereNode
        case .white:
            return whiteReferenceSphereNode
        case .black:
            return blackReferenceSphereNode
        case .yellow:
            return yellowReferenceSphereNode
        }
        
    }
}
