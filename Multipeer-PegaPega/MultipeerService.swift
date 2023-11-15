import Foundation
import MultipeerConnectivity

protocol MultipeerServiceDelegate {
    func connectedDevicesChanged(manager : MultipeerService, connectedDevices: [String])
    func positionChanged(manager : MultipeerService, positionString: String, forPeer peerID: String)
    func addPlayer(peerID: String, color: UIColor)
}

class MultipeerService : NSObject, ObservableObject {
    
    // VARIÁVEIS
    var peersWithNodes = Set<String>()
    private let MultipeerServiceType = "peer-position"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private var serviceAdvertiser : MCNearbyServiceAdvertiser
    private let serviceBrowser : MCNearbyServiceBrowser
    private var invitedPeers = Set<MCPeerID>()
    
    @Published var connectState:Bool = false
    @Published var peers: [PeerDevice] = []
    @Published var joinedPeer: [PeerDevice] = []
    @Published var selectedPeer: PeerDevice? { didSet { connect() } }
    @Published var isAdvertising: Bool = false {
        didSet {
            isAdvertising ? serviceAdvertiser.startAdvertisingPeer() : serviceAdvertiser.stopAdvertisingPeer()
        }
    }
    
    @Published var isHost: Bool = false
    
    // DELEGATE
    var delegate : MultipeerServiceDelegate?
    
    // SESSÃO
    lazy var session : MCSession = {
        let session = MCSession(peer: self.myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    // INIT
    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: MultipeerServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
        self.serviceBrowser.startBrowsingForPeers()
    }
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    // ENVIAR POSITION
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
    
    func startBrowsing() {
        print("começou a procurar dispositivos")
        serviceBrowser.startBrowsingForPeers()
    }
    
    func stopBrowsing() {
        print("parou de procurar dispositivos")
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func startHosting() {
        print("começar host")
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: MultipeerServiceType)
        serviceAdvertiser.delegate = self
        serviceAdvertiser.startAdvertisingPeer()
    }
    
    
    // CONECTAR
    private func connect() {
        guard let selectedPeer else {
            return
        }
        
        if !invitedPeers.contains(selectedPeer.peerID) {
                    invitedPeers.insert(selectedPeer.peerID)
                    serviceBrowser.invitePeer(selectedPeer.peerID, to: session, withContext: nil, timeout: 10)
                }
    }
    
    // SHOW
    func addPlayerToArray(peerID: MCPeerID) {
        guard let first = peers.first(where: { $0.peerID == peerID }) else {
            return
        }
        
        joinedPeer.append(first)
    }
}

// MARK: - ADVERTISER
extension MultipeerService : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        
        invitationHandler(true, self.session)
    }
}

// MARK: - BROWSER
extension MultipeerService : MCNearbyServiceBrowserDelegate {
    
    // Nearby service browser delegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
                NSLog("%@", "foundPeer: \(peerID)")
                if !peers.contains(where: { $0.peerID == peerID }) && !session.connectedPeers.contains(peerID) && !invitedPeers.contains(peerID) {
                    peers.append(PeerDevice(peerID: peerID))
                    invitedPeers.insert(peerID)
                    browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
                }
            }

            // Perda de conexão com um peer
            func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
                NSLog("%@", "lostPeer: \(peerID)")
                peers.removeAll(where: { $0.peerID == peerID })
                invitedPeers.remove(peerID) // Também remova da lista de peers convidados
            }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
}

// MARK: - SESSION
extension MultipeerService : MCSessionDelegate {
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        // DELEGATE
        self.delegate?.connectedDevicesChanged(manager: self, connectedDevices: session.connectedPeers.map{$0.displayName})
        
        // ESTADO DA CONEXÃO
        DispatchQueue.main.async {
            switch state {
            case .connecting:
                print("\(peerID) state: connecting")
            case .connected:
                print("\(peerID) state: CONNECTED!")
                self.connectState = true
                //self.getListPeople()
            case .notConnected:
                print("\(peerID) state: NOT CONNECTED!")
                self.connectState = false
                //self.getListPeople()
            @unknown default:
                print("\(peerID) state: unknown")
            }
        }
        
        // THAINA
        if state == .connected && !peersWithNodes.contains(peerID.displayName) {
            self.delegate?.addPlayer(peerID: peerID.displayName, color: UIColor.black)
            peersWithNodes.insert(peerID.displayName)
        }
    }
    
    // dados recebidos
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        let positionString = String(data: data, encoding: .utf8)!
        // passa a id do peer quando inicia a sessão
        self.delegate?.positionChanged(manager: self, positionString: positionString, forPeer: peerID.displayName)
        
        print("Session 1")
        DispatchQueue.main.async {
            let command = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String
            print("command -> \(command)")
        }
    }
    
    // Outros métodos da sessão que não são usados:
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Session 2")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Session 3")
    }
    
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        print("Session 4")
    }
    
    func send() {
        do{
            let startCommand = "HALOGES"
            let message = startCommand.data(using: String.Encoding.utf8, allowLossyConversion: false)
            try self.session.send(message!, toPeers: self.session.connectedPeers, with: .unreliable)
        } catch {
            print("ERROR MESSAGE -> \(error.localizedDescription)")
        }
    }

}
