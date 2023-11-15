//
//  PlayerInfo.swift
//  Multipeer-PegaPega
//
//  Created by Leonardo Mota on 15/11/23.
//

import MultipeerConnectivity
import SwiftUI


struct PlayerInfo: Codable {
    var displayName: String
    var deviceName: String {
        return UIDevice.current.name
    }
    
    var role: Player.Role
    
    init(peerID: MCPeerID, role: Player.Role) {
        self.displayName = peerID.displayName
        self.role = role
    }
    

    init(fromPlayer player: Player) {
        self.init(peerID: player.peerID, role: player.role)
    }
}


