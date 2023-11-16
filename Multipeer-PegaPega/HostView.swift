////
////  HostView.swift
////  Multipeer-PegaPega
////
////  Created by Leonardo Mota on 14/11/23.
////
//
//import SwiftUI
//
//struct HostView: View {
//    
//    @StateObject private var sessionController = MultipeerService()
//    @State private var connectedPeers: [String] = []
//    @State private var connectionLabel: String = ""
//    @State private var isGameStarted = false
//    
//    var body: some View {
//        VStack {
//            Text("Pega-Pega")
//                .font(.title)
//                .bold()
//            
//            Text("Multipeer")
//                .font(.subheadline)
//                .foregroundStyle(.black.opacity(0.5))
//            
//            
//            if sessionController.peers.isEmpty {
//                Text("Procurando sessões...")
//                Toggle("Criar sessão", isOn: $sessionController.isAdvertising)
//                    .toggleStyle(.switch)
//                    .padding()
//            } else {
//                ForEach(sessionController.peers) { peer in
//                    Button(action: {
//                        sessionController.selectedPeer = peer
//                        sessionController.addPlayerToArray(peerID: peer.peerID)
//                        //isConnecting = true
//                    }) {
//
//                        Text("Conectar à \(peer.peerID.displayName)")
//                        
//                    }
//                }
//            }
//            
//            Spacer()
//            Button("Iniciar Jogo"){
//                isGameStarted = true
//            }
//            //.disabled(connectedPeers.count > 2)
//            Text("JOGADORES")
//                .font(.title2)
//            Text("\(connectedPeers.count + (sessionController.isAdvertising || sessionController.connectState ? 1 : 0)) / 7")
//                .font(.largeTitle)
//                .bold()
//            Text("conectados: \(connectionLabel)")
//            Spacer()
//            ScrollView(.horizontal) {
//                HStack(spacing: 10) {
//                    if sessionController.isAdvertising || sessionController.connectState{
//                        PeerCard(peerName: "You", playerNumber: 1)
//                    }
//                    ForEach(0..<connectedPeers.count, id: \.self) { index in
//                        let peerName = connectedPeers[index]
//                        PeerCard(peerName: peerName, playerNumber: index + 2)
//                        let _ = print("Connected Peers: \(connectedPeers.count)")
//                    }
//                }
//                .padding(10)
//            }
//            
//            
//            Spacer()
//            
//            Text("Esperando jogadores...")
//                .foregroundStyle(.black.opacity(0.5))
//                .font(.headline)
//        }
//        .onAppear {
//            self.sessionController.delegate = self
//        }
//        .padding(.vertical, 30)
//        .fullScreenCover(isPresented: $isGameStarted){
//            ContentView(connectionsLabel: "Connected devices: ", backgroundColor: .yellow)
//                
//        }
//    }
//}
//
//struct PeerCard: View {
//    var peerName: String
//    var playerNumber: Int
//    
//    var body: some View {
//        VStack {
//            Text("Player \(playerNumber)")
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            Text(peerName)
//                .font(.headline)
//                .foregroundColor(.primary)
//                .padding(.bottom, 5)
//            
//            Circle()
//                .frame(width: 40, height: 40)
//                .foregroundColor(.green)
//        }
//        .padding()
//        .background(Color.white)
//        .cornerRadius(10)
//        .shadow(radius: 3)
//    }
//}
//
//extension HostView {
//    func connectedDevicesChanged(manager: MultipeerService, connectedDevices: [String]) {
//        DispatchQueue.main.async {
//            self.connectedPeers = connectedDevices
//            
//        }
//    }
//    
//    func positionChanged(manager: MultipeerService, positionString: String, forPeer peerID: String) {
//        
//    }
//    
//    func addPlayer(peerID: String, color: UIColor) {
//        
//    }
//    
//    
//}
//
//#Preview {
//    HostView()
//}
