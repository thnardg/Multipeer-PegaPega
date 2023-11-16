//
//  GameSceneView.swift
//  Multipeer-PegaPega
//
//  Created by Thayna Rodrigues on 16/11/23.
//

import SwiftUI
import SpriteKit

struct GameSceneView: View {
    @State var connectionsLabel: String = "Connected devices: "
    @State var backgroundColor: Color = .black
    
    let multipeerService = MultipeerService() // instancia do multipeer
    
    @State var scene: GameScene = GameScene(size: CGSize(width: 1080, height: 1920))
    
    var body: some View {
        ZStack{
            backgroundColor.edgesIgnoringSafeArea(.all)
            VStack{
                SpriteView(scene: scene).ignoresSafeArea(.all) // Game Scene
            }
        }.onAppear() {
            self.multipeerService.delegate = self
        }
    }
}

// MARK: -- Funções do protocolo MultipeerServiceDelegate
extension GameSceneView : MultipeerServiceDelegate {
    func didReceiveHostPlayerID(_ hostPlayerID: String) {
        DispatchQueue.main.async {
            self.scene.hostPlayerID = hostPlayerID
        }
    }
    
    func addPlayer(peerID: String) {
        scene.addPlayer(forPeer: peerID)
    }
    
    func positionChanged(manager: MultipeerService, positionString: String, forPeer peerID: String) {
        if let position = parseCGPoint(from: positionString) {
            scene.moveNode(forPeer: peerID, to: position)
        }
    }
    
    // Conversão da localização de String pra CGPoint
    private func parseCGPoint(from string: String) -> CGPoint? {
        let components = string.components(separatedBy: ",")
        
        guard components.count == 2,
              let x = Double(components[0]),
              let y = Double(components[1]) else {
            return nil
        }
        
        return CGPoint(x: x, y: y)
    }
}

