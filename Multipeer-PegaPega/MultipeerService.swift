import Foundation
import MultipeerConnectivity

protocol MultipeerServiceDelegate {
    func connectedDevicesChanged(manager : MultipeerService, connectedDevices: [String])
    func positionChanged(manager : MultipeerService, positionString: String, forPeer peerID: String)
    func addPlayer(peerID: String, color: UIColor)
}

class MultipeerService : NSObject {
    var peersWithNodes = Set<String>()
    private let MultipeerServiceType = "peer-position"
    private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    var delegate : MultipeerServiceDelegate?
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: MultipeerServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: MultipeerServiceType)
        super.init()
        self.serviceAdvertiser.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    func send(position : String) {
        NSLog("%@", "sendPosition: \(position) to \(session.connectedPeers.count) peers,\(session.connectedPeers.self)")
        if session.connectedPeers.count > 0 {
            do {
                try self.session.send(position.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            }
            catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
    }
}
extension MultipeerService : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, self.session)
    }
}
extension MultipeerService : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
}
extension MultipeerService : MCSessionDelegate {
        
        func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
            NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
            self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
                                                    session.connectedPeers.map{$0.displayName})
            if state == .connected && !peersWithNodes.contains(peerID.displayName) {
                self.delegate?.addPlayer(peerID: peerID.displayName, color: UIColor.black)
                peersWithNodes.insert(peerID.displayName)
            }
        }
    
    // Chamado quando dados são recebidos de um dispositivo na sessão
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        let positionString = String(data: data, encoding: .utf8)!
        // passa a id do peer quando inicia a sessão
        self.delegate?.positionChanged(manager: self, positionString: positionString, forPeer: peerID.displayName)
    }
    
    // Outros métodos da sessão que não são usados:
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveStream")
    }
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        NSLog("%@", "didStartReceivingResourceWithName")
    }
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        NSLog("%@", "didFinishReceivingResourceWithName")
    }
}
