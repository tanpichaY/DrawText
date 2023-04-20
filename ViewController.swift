//
//  ViewController.swift
//  AR Drawing
//
//  Created by Thanphicha Yimlamai on 28/10/2565 BE.
//

import UIKit
import ARKit
import SceneKit
import CoreData
class ViewController: UIViewController {
    
    //IBOutlet
    
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var colorPickerView: UIView!
    @IBOutlet weak var undoButton: UIButton!
    @IBOutlet weak var saveErrorLabel: UIButton!
    
    //Properties
    var previousPoint: SCNVector3?
    var currentPosition: CGPoint?
    var strokeAnchorIDs: [UUID] = []
    var currentStrokeAnchorNode: SCNNode?
    var currentStrokeColor: StrokeColor = .white
    var isLoadingSavedWorldMap = false
    let sphereNodesManager = SphereNodesManager()
    
    //loadview
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Prevent the screen from being dimmed
        UIApplication.shared.isIdleTimerDisabled = true
        
        sceneView.preferredFramesPerSecond = 60
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        let scene = SCNScene()
        sceneView.scene = scene
        
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
        hideAllUI()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapUndoButton))
        undoButton.addGestureRecognizer(tapGesture)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    func hideAllUI() {
        DispatchQueue.main.async {
           
            self.colorPickerView.isHidden = true
            
            self.saveErrorLabel.isHidden = true
            
        }
    }
    
    private func showAllUI() {
        DispatchQueue.main.async {
            
            self.colorPickerView.isHidden = false
        }
    }
    
    //Draw
    private func createSphereAndInsert(atPositions positions: [SCNVector3], andAddToStrokeAnchor strokeAnchor: StrokeAnchor) {
        for position in positions {
            createSphereAndInsert(atPosition: position, andAddToStrokeAnchor: strokeAnchor)
        }
    }
    
    private func createSphereAndInsert(atPosition position: SCNVector3, andAddToStrokeAnchor strokeAnchor: StrokeAnchor) {
        guard let currentStrokeNode = currentStrokeAnchorNode else {
            return
        }
        // Get the reference sphere node and clone it
        let referenceSphereNode = sphereNodesManager.getReferenceSphereNode(forStrokeColor: strokeAnchor.color)
        let newSphereNode = referenceSphereNode.clone()
        // Convert the position from world transform to local transform (relative to the anchors default node)
        let localPosition = currentStrokeNode.convertPosition(position, from: nil)
        newSphereNode.position = localPosition
        // Add the node to the default node of the anchor
        currentStrokeNode.addChildNode(newSphereNode)
        // Add the position of the node to the stroke anchors sphereLocations array (Used for saving/loading the world map)
        strokeAnchor.sphereLocations.append([newSphereNode.position.x, newSphereNode.position.y, newSphereNode.position.z])
    }
    
    private func anchorForID(_ anchorID: UUID) -> StrokeAnchor? {
        return sceneView.session.currentFrame?.anchors.first(where: { $0.identifier == anchorID }) as? StrokeAnchor
    }
    
    private func sortStrokeAnchorIDsInOrderOfDateCreated() {
        var strokeAnchorsArray: [StrokeAnchor] = []
        for anchorID in strokeAnchorIDs {
            if let strokeAnchor = anchorForID(anchorID) {
                strokeAnchorsArray.append(strokeAnchor)
            }
        }
        strokeAnchorsArray.sort(by: { $0.dateCreated < $1.dateCreated })
        
        strokeAnchorIDs = []
        for anchor in strokeAnchorsArray {
            strokeAnchorIDs.append(anchor.identifier)
        }
    }
    
    //func changeSaveButtonStyle(withStatus status: ARFrame.WorldMappingStatus) {
        //switch status {
        //case .notAvailable, .limited:
            //uploadButton.backgroundColor = UIColor.gray
        //case .extending, .mapped:
            //uploadButton.backgroundColor = UIColor.white
        //}
    //}
    
    
    
    //Alert
    func showAlert(withTitle title: String, andMessage message: String?, completionHandler: (() -> ())? = nil) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let alertAction = UIAlertAction(title: "OK", style: .cancel) { (_) in
                completionHandler?()
            }
            alertController.addAction(alertAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    //Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Do not let the user draw if the world map is relocalizing
        if isLoadingSavedWorldMap {
            return
        }
        // Hide the additional buttons view if it's showing
        
        // Create a StrokeAnchor and add it to the Scene (One Anchor will be added to the exaction position of the first sphere for every new stroke)
        guard let touch = touches.first else { return }
        guard let touchPositionInFrontOfCamera = getPosition(ofPoint: touch.location(in: sceneView), atDistanceFromCamera: 0.2, inView: sceneView) else { return }
        // Convert the position from SCNVector3 to float4x4
        let strokeAnchor = StrokeAnchor(name: "strokeAnchor", transform: float4x4(float4(1, 0, 0, 0),
                                                                                  float4(0, 1, 0, 0),
                                                                                  float4(0, 0, 1, 0),
                                                                                  float4(touchPositionInFrontOfCamera.x,
                                                                                         touchPositionInFrontOfCamera.y,
                                                                                         touchPositionInFrontOfCamera.z,
                                                                                         1)))
        strokeAnchor.color = currentStrokeColor
        sceneView.session.add(anchor: strokeAnchor)
        currentPosition = touch.location(in: sceneView)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentPosition = touch.location(in: sceneView)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousPoint = nil
        currentStrokeAnchorNode = nil
        currentPosition = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        previousPoint = nil
        currentStrokeAnchorNode = nil
        currentPosition = nil
    }
    
    @objc func tapUndoButton(gesture: UITapGestureRecognizer) {
        print("pressed")
        for strokeAnchorID in strokeAnchorIDs {
            if let strokeAnchor = anchorForID(strokeAnchorID) {
                sceneView.session.remove(anchor: strokeAnchor)
            }
        }
        currentStrokeAnchorNode = nil
    }
    
    //IBAction
    
    @IBAction func readMode(_ sender: Any) {
        
    }
    
    @IBAction func uploadMethod(_ sender: UIButton) {
           
        }
    
    @IBAction func pickColor(_ sender: UIButton) {
        saveErrorLabel.isHidden = true
        colorPickerView.isHidden = false
    }
    
    @IBAction func undoMethod(_ sender: UIButton) {
        saveErrorLabel.isHidden = true
        sortStrokeAnchorIDsInOrderOfDateCreated()
        
        guard let currentStrokeAnchorID = strokeAnchorIDs.last, let curentStrokeAnchor = anchorForID(currentStrokeAnchorID) else {
            print("No stroke to remove")
            return
        }
        sceneView.session.remove(anchor: curentStrokeAnchor)

        // add this?
        currentStrokeAnchorNode = nil
    }
    
    @IBAction func whiteButton(_ sender: Any) {
        currentStrokeColor = .white
        colorPickerView.isHidden = true
    }
    @IBAction func blackButton(_ sender: Any) {
        currentStrokeColor = .black
        colorPickerView.isHidden = true
    }
    @IBAction func blueButton(_ sender: Any) {
        currentStrokeColor = .blue
        colorPickerView.isHidden = true
    }
    @IBAction func greenButton(_ sender: Any) {
        currentStrokeColor = .green
        colorPickerView.isHidden = true
    }
    @IBAction func yellowButton(_ sender: Any) {
        currentStrokeColor = .yellow
        colorPickerView.isHidden = true
    }
    @IBAction func redButton(_ sender: Any) {
        currentStrokeColor = .red
        colorPickerView.isHidden = true
    }
}

//ARsession delegate
extension ViewController: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        //changeSaveButtonStyle(withStatus: frame.worldMappingStatus)
        
        // Draw the spheres
        guard let currentStrokeAnchorID = strokeAnchorIDs.last else { return }
        let currentStrokeAnchor = anchorForID(currentStrokeAnchorID)
        if currentPosition != nil && currentStrokeAnchor != nil {
            guard let currentPointPosition =
                getPosition(ofPoint: currentPosition!, atDistanceFromCamera: 0.2, inView: sceneView) else { return }
            
            if let previousPoint = previousPoint {
                // Do not create any new spheres if the distance hasn't changed much
                let distance = abs(previousPoint.distance(vector: currentPointPosition))
                if distance > 0.00104 {
                    createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                    // Draw spheres between the currentPoint and previous point if they are further than the specified distance (Otherwise fast movement will make the line blocky)
                    // TODO: The spacing should depend on the brush size
                    let positions = getPositionsOnLineBetween(point1: previousPoint, andPoint2: currentPointPosition, withSpacing: 0.001)
                    createSphereAndInsert(atPositions: positions, andAddToStrokeAnchor: currentStrokeAnchor!)
                    self.previousPoint = currentPointPosition
                }
            } else {
                createSphereAndInsert(atPosition: currentPointPosition, andAddToStrokeAnchor: currentStrokeAnchor!)
                self.previousPoint = currentPointPosition
            }
        }
    }
}

// MARK:- ARSCNViewDelegate

extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // This is only used when loading a worldMap
        if let strokeAnchor = anchor as? StrokeAnchor {
            currentStrokeAnchorNode = node
            strokeAnchorIDs.append(strokeAnchor.identifier)
            for sphereLocation in strokeAnchor.sphereLocations {
                createSphereAndInsert(atPosition: SCNVector3Make(sphereLocation[0], sphereLocation[1], sphereLocation[2]), andAddToStrokeAnchor: strokeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        // Remove the anchorID from the strokes array
        print("Anchor removed")
        strokeAnchorIDs.removeAll(where: { $0 == anchor.identifier })
    }
}
