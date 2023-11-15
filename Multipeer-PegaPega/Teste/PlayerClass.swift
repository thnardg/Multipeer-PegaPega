//
//  PlayerClass.swift
//  Multipeer-PegaPega
//
//  Created by Leonardo Mota on 15/11/23.
//

import MultipeerConnectivity
import SwiftUI


struct SentData: Codable {
    var description: SentDataDescription
    var content: Data
    
    enum SentDataDescription: Codable {
        case lobbyInfo
        case lobbyInfoRequest
    }
}

class Player: NSObject, ObservableObject {
    
    @StateObject private var viewModel = ContentView2ViewModel()
    var peerID: MCPeerID!
    var session: MCSession!
    //let serviceType = "teste-mp"
    
    var lobbyMembers: [PlayerInfo]?
    
    /* A weak property to hold the lobby that the host is in. It is declared weak to avoid a strong-reference cyle. The LobbyViewController
  holds a strong reference to the player already */
    weak var lobby: ContentView2ViewModel?
    
    var role: Role
    
    // Enumeration to hold all currently possible roles a player may have
    enum Role: Codable {
        case player
        case host
        case none
        
        static func roleTitle(from role: Role) -> String {
            switch role {
            case .host:
                return "Host"
                
            default:
                return ""
            }
        }
    }

    init(displayName: String = UIDevice.current.name, role: Role = .none) {
        self.role = role
        self.peerID = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        
        super.init()
        self.session.delegate = self
    }
    
    func requestLobbyInfo(from peer: MCPeerID) {
        print("From \(peerID.displayName): Attempting to request lobby info from \(peer.displayName)")
      
        let sentData = SentData(description: .lobbyInfoRequest, content: Data())
        
        do {
            let jsonEncoder = JSONEncoder()
            let encodedRequest = try jsonEncoder.encode(sentData)
            
            try session.send(encodedRequest, toPeers: [peer], with: .reliable)
        } catch {
            print("Failed to request lobby info from \(peer).\n\(error)")
        }
    }
    
    // A method to send lobby info to the requesting peer
    func sendLobbyInfo(to peer: MCPeerID) {
        print("From \(peerID.displayName): Attempting to send lobby info to \(peer.displayName)")
        
        // Safely unwrap the lobbyMembers property before sending the lobby info
        guard let lobbyMembers = self.viewModel.lobbyMembers else {
            fatalError("Lobby members are nil in ViewModel")
        }
        
        do {
            let lobbyMembersInfo = lobbyMembers + [PlayerInfo(fromPlayer: self)]
            
            let jsonEncoder = JSONEncoder()
            
            let encodedLobbyMembersInfo = try jsonEncoder.encode(lobbyMembersInfo)
            
            // Next, initialize and encode a new 'SentData' object with the correct description and content
            let sentData = SentData(description: .lobbyInfo, content: encodedLobbyMembersInfo)
            let encodedSentData = try jsonEncoder.encode(sentData)
            
            // Attempt to send the 'SentData' object to the peer who requested info
            try session.send(encodedSentData, toPeers: [peer], with: .reliable)
            print("From \(peerID.displayName): Successfully sent data to \(peer.displayName)")
        } catch {
            print("Failed to send lobby info to \(peer).\n\(error)")
        }
    }

    
    func hostLobby() {
        role = .host
    }
    
    /* This method is also unfinished. Right now, it just changes the role of the current instance of the 'Player' class to none since it won't
  be in a lobby anymore. It also changes the lobby to nil in case it had a value already */
    func leaveLobby() {
        role = .none
        lobby = nil
    }
}

// Conform the Player to 'MCSessionDelegate' protocol
extension Player: MCSessionDelegate {
    
    func session(_ session: MCSession, peer: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            
            print("From \(peerID.displayName): Connected to \(peer.displayName)")
            
            // When the state is connected, make sure the role of the current instance of 'Player' is not host and request lobby info from the host
            if role != .host {
                requestLobbyInfo(from: peer)
            }
            
        case .connecting:
            print("From \(peerID.displayName): Connecting to \(peer.displayName)")
            
        case .notConnected:
            print("From \(peerID.displayName): \(peer.displayName) is not connected")
            
        default:
            print("From \(peerID.displayName): Unknown State - \(peer.displayName)")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peer: MCPeerID) {
        print("From \(peerID.displayName): Received data from \(peer.displayName)")
        let jsonDecoder = JSONDecoder()
        
        if let sentData = try? jsonDecoder.decode(SentData.self, from: data) {
            
            // Determine what kind of sent data was received
            switch sentData.description {
            case .lobbyInfoRequest:
                sendLobbyInfo(to: peer)
                
            case .lobbyInfo:
                do {
                    let lobbyMembersInfo = try jsonDecoder.decode([PlayerInfo].self, from: sentData.content)
                    
                    self.lobbyMembers = lobbyMembersInfo
                    print("Received lobby info")
                } catch {
                    print("Failed to retrieve lobby hosting info.\n\(error)")
                }
            }
        } else {
            print("Did not receive 'SentData' object")
        }
    }
    
    // These are protocol stubs required for conformance to MCSessionDelegate
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
}

