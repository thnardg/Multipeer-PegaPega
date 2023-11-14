import SwiftUI
import SpriteKit

struct ContentView: View {
    @State var connectionsLabel: String
    @State var backgroundColor: Color
    let multipeer = MultipeerService()
    
    @State var scene: GameScene = GameScene(size: CGSize(width: 300, height: 400))
    
    var body: some View {
        ZStack{
            backgroundColor.edgesIgnoringSafeArea(.all)
            VStack{
                Text(self.connectionsLabel)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
                SpriteView(scene: scene)
                    .frame(width: 300, height: 400)
                Spacer()
            }
        }.onAppear() {
            self.multipeer.delegate = self
        }
    }
}

extension ContentView : MultipeerServiceDelegate {

    func addPlayer(peerID: String, color: UIColor) {
            addPlayerNode(peerID: peerID, color: color)
        }
    
    func addPlayerNode(peerID: String, color: UIColor) {
        scene.addPlayer(forPeer: peerID, color: color)
    }
    
    func positionChanged(manager: MultipeerService, positionString: String, forPeer peerID: String) {
        if let position = parseCGPoint(from: positionString) {
            scene.moveNode(forPeer: peerID, to: position)
        }
    }
    
    func connectedDevicesChanged(manager: MultipeerService, connectedDevices: [String]) {
        OperationQueue.main.addOperation {
            self.connectionsLabel = "Connected devices: \(connectedDevices)"
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
