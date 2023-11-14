//
//  PeerDevice.swift
//  Multipeer-PegaPega
//
//  Created by Leonardo Mota on 14/11/23.
//

import MultipeerConnectivity

struct PeerDevice: Identifiable, Hashable {
    let id = UUID()
    let peerID: MCPeerID // MCPeerID representa um "peer" em uma sessão Multipeer
    var isHost: Bool = false
}
