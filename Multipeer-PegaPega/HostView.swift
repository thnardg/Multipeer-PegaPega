//
//  HostView.swift
//  Multipeer-PegaPega
//
//  Created by Leonardo Mota on 14/11/23.
//

import SwiftUI

struct HostView: View {
    
    @EnvironmentObject var sessionController : MultipeerService
    @State private var connectedPeers: [String] = []
    @State private var connectionLabel: String = ""
    
    var body: some View {
        VStack {
            Text("Pega-Pega")
                .font(.title)
                .bold()
            
            Text("Multipeer")
                .font(.subheadline)
                .foregroundStyle(.black.opacity(0.5))
            
            Spacer()
            
            if sessionController.peers.isEmpty {
                Text("Procurando sessões...")
                    .foregroundStyle(.gray)
                Toggle(sessionController.isAdvertising ? "Hospedando!" : "Criar sessão", isOn: $sessionController.isAdvertising)
                    .toggleStyle(.button)
                    .padding()
                    .onChange(of: sessionController.isAdvertising) { _, isAdvertising in
                        sessionController.updateLocalDeviceAsHost()
                    }
            } else {
                ForEach(sessionController.peers) { peer in
                    Button(action: {
                        sessionController.selectedPeer = peer
                        sessionController.addPlayerToArray(peerID: peer.peerID)
                        //isConnecting = true
                    }) {

                        Text("Conectar à \(peer.peerID.displayName)")
                        
                    }
                }
            }
            
            Divider()
          
            Text("JOGADORES")
                .font(.title2)
            Text("\(connectedPeers.count + sessionController.peers.count) / 7")
                .font(.largeTitle)
                .bold()
            Text("conectados: \(connectedPeers.count)")
            Text("PEERWITHNODES: \(sessionController.peersWithNodes.count)")
    
            Spacer()
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(0..<(connectedPeers.count), id: \.self) { index in
                        let peerName = connectedPeers[index]
                        PeerCard(peerName: peerName, playerNumber: index + 1)
                    }
                    if !sessionController.peers.isEmpty {
                        PeerCard(peerName: "HOST", playerNumber: 0)
                    }
                }
                .padding(10)
            }
            Spacer()
            
            Text("Esperando jogadores...")
                .foregroundStyle(.black.opacity(0.5))
                .font(.headline)
        }
        .onAppear {
            self.sessionController.delegate = self
        }
        .padding(.vertical, 30)
    }
}

struct PeerCard: View {
    var peerName: String
    var playerNumber: Int
    
    var body: some View {
        VStack {
            Text("Player \(playerNumber)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(peerName)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.bottom, 5)
            
            Circle()
                .frame(width: 80, height: 80)
                .foregroundColor(.purple)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
    }
}

extension HostView: MultipeerServiceDelegate {
    func connectedDevicesChanged(manager: MultipeerService, connectedDevices: [String]) {
        DispatchQueue.main.async {
            self.connectedPeers = connectedDevices
            print("connectedDevices: \(connectedDevices)")
            print("PEERS: \(sessionController.peers)")
            print("JOINED: \(sessionController.joinedPeer)")
            print("WITHNODES: \(sessionController.peersWithNodes)")
            
        }
    }
    
    func positionChanged(manager: MultipeerService, positionString: String, forPeer peerID: String) {
        
    }
    
    func addPlayer(peerID: String, color: UIColor) {
        
    }
    
    
}

#Preview {
    HostView()
        .environmentObject(MultipeerService())
}
