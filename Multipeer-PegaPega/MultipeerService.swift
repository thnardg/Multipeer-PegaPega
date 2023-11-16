//
//  GameSceneView.swift
//  Multipeer-PegaPega
//
//  Created by Thayna Rodrigues on 16/11/23.
//

import MultipeerConnectivity

// MARK: PROTOCOLOS
// Protocolo para definir os métodos que lidam com eventos de comunicação do multipeer
protocol MultipeerServiceDelegate {
    func positionChanged(manager: MultipeerService, positionString: String, forPeer peerID: String)
    func addPlayer(peerID: String)
    func didReceiveHostPlayerID(_ hostPlayerID: String)
}

// MARK: -- MULTIPEER SERVICE
class MultipeerService: NSObject {

    var delegate: MultipeerServiceDelegate?
    
    // Multipeer Service
    private let MultipeerServiceType = "peer-position"
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    
    let myPeerId = MCPeerID(displayName: UIDevice.current.name) // dispositivo local
    var peersWithNodes = Set<String>() // nodes criados para os peers
    
    // Inicia a sessão do multipeer
    lazy var session: MCSession = {
        let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        return session
    }()
    
    override init() {
        // Init do advertiser e do browser
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: MultipeerServiceType)
        self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: MultipeerServiceType)
        
        super.init()
        
        self.serviceAdvertiser.delegate = self
        self.serviceBrowser.delegate = self
        
        // Começa a anuciar/buscar outros peers
        self.serviceAdvertiser.startAdvertisingPeer()
        self.serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
        self.serviceBrowser.stopBrowsingForPeers()
    }
    
    // Envia a posição do node pros outros peers
    func send(position: String) {
        NSLog("%@", "sendPosition: \(position) to \(session.connectedPeers.count) peers, \(session.connectedPeers.self)")
        if session.connectedPeers.count > 0 {
            do {
                // Envia pros peers conectados
                try self.session.send(position.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
            } catch let error {
                NSLog("%@", "Error for sending: \(error)")
            }
        }
    }
    
    // Envia a id do host pros outros peers
    func sendHostPlayerID(_ hostPlayerID: String) {
        do {
            if let data = hostPlayerID.data(using: .utf8) {
                try self.session.send(data, toPeers: session.connectedPeers, with: .reliable)
            }
        } catch let error {
            NSLog("%@", "Error for sending hostPlayerID: \(error)")
        }
    }
}

// Extensão para lidar com a sessão
// MARK: -- SESSION
extension MultipeerService: MCSessionDelegate {
    // Função chamada quando o estado de um dos peers muda
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        NSLog("%@", "peer \(peerID) didChangeState: \(state.rawValue)")
        if state == .connected && !peersWithNodes.contains(peerID.displayName) {
            // Notifica ao delegate que um peer novo entrou na sessão
            self.delegate?.addPlayer(peerID: peerID.displayName)
            peersWithNodes.insert(peerID.displayName)
        }
    }
    
    // Função chamada quando um dado novo é recebido pelos peers
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        NSLog("%@", "didReceiveData: \(data)")
        // Checa se o dado recebido é uma posição ou o id do host
        if let positionString = String(data: data, encoding: .utf8) {
            self.delegate?.positionChanged(manager: self, positionString: positionString, forPeer: peerID.displayName)
        }
        if let hostPlayerID = String(data: data, encoding: .utf8) {
            self.delegate?.didReceiveHostPlayerID(hostPlayerID)
        }
    }

    // Outros métodos não utilizados
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

// MARK: -- ADVERTISER
extension MultipeerService: MCNearbyServiceAdvertiserDelegate {
    // Função chamada quando um peer aceita o convite do advertiser
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
        // Aceita o convite automaticamente e envia os dados pra sessão
        invitationHandler(true, self.session)
    }
    
    // Em caso de erro no advertiser
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
    }
}

// MARK: -- BROWSER
extension MultipeerService: MCNearbyServiceBrowserDelegate {
    // Função chamadsa quando um peer é encontrado
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        NSLog("%@", "foundPeer: \(peerID)")
        NSLog("%@", "invitePeer: \(peerID)")
        // Convite para entrar na sessão
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    // Função chamada quando um peer é desconectado/perdido
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("%@", "lostPeer: \(peerID)")
    }
    
    // Em caso de erro no browser
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
    }
    
}
