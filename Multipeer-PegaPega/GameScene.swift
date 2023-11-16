//
//  GameSceneView.swift
//  Multipeer-PegaPega
//
//  Created by Thayna Rodrigues on 16/11/23.
//

import SpriteKit
import MultipeerConnectivity

class GameScene: SKScene, SKPhysicsContactDelegate {
    let multipeerService = MultipeerService() // instancia do multiper service
    var playerNodes: [String: (node: SKSpriteNode, isSafe: Bool)] = [:]
    var hostPlayerID: String?
    private let pushPush = PushNotifications()

    let playerSpacing: CGFloat = 200 // temp
    var gameOverLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        pushPush.initCloud()
        
        // Game Over label
        gameOverLabel = SKLabelNode(text: "Fim de jogo")
        gameOverLabel.fontSize = 30
        gameOverLabel.fontColor = .white
        gameOverLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        gameOverLabel.isHidden = true
        self.addChild(gameOverLabel)
    }
    
    // MARK: Adiciona os nodes da cena
    func addPlayer(forPeer peerID: String) {
        let color: UIColor
        var isSafe = true // todos os players iniciam como safe
        
        if hostPlayerID == nil { // caso o host id esteja vazio, o peer vira o host
            hostPlayerID = peerID
            multipeerService.sendHostPlayerID(hostPlayerID!) // envia a id de host pra todos os peers
            
            color = .red // o host começa vermelho e com o status de safe = false
            isSafe = false
        } else {
            color = .systemMint // todos os outros são verdes
        }
        
        // Adiciona um novo node na tela a partir do número de peers:
        let newPlayer = SKSpriteNode(color: color, size: CGSize(width: 80, height: 80))
        let numberOfPlayers = playerNodes.count
        let xOffset = CGFloat(numberOfPlayers) * playerSpacing
        newPlayer.position = CGPoint(x: self.frame.midX + xOffset, y: self.frame.midY)
        self.addChild(newPlayer)
        
        // Setup dos nodes
        newPlayer.name = peerID // define um nome pro peerID pra usar na função de colisão
        newPlayer.physicsBody = SKPhysicsBody(rectangleOf: newPlayer.size)
        newPlayer.physicsBody?.isDynamic = true
        newPlayer.physicsBody?.allowsRotation = false
        newPlayer.physicsBody?.affectedByGravity = false
        newPlayer.physicsBody?.categoryBitMask = 1
        newPlayer.physicsBody?.contactTestBitMask = 1
        newPlayer.physicsBody?.collisionBitMask = 1
        
        playerNodes[peerID] = (node: newPlayer, isSafe: isSafe)
    }
    
    // Animação que move o node no dispositivo dos peers
    func moveNode(forPeer peerID: String, to position: CGPoint) {
        playerNodes[peerID]?.node.run(SKAction.move(to: position, duration: 0.1))
    }


    // Move o node no meu dispositivo
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            
            let positionString = "\(location.x),\(location.y)"
            multipeerService.send(position: positionString) // envia a posição pelo multipeer
        }
    }
    
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Verifica se dois objetos se tocando tem um node e dá um nome pra cada
        guard let nodeAName = contact.bodyA.node?.name, let nodeBName = contact.bodyB.node?.name else { return }
        
        // Checa se os nodes são players
        if var playerA = playerNodes[nodeAName], var playerB = playerNodes[nodeBName] {
            // Se qualquer um dos player não estiver salvo, ambos ficam pegos/não-salvos
            if !playerA.isSafe || !playerB.isSafe {
                playerA.node.color = .red
                playerB.node.color = .red
                playerA.isSafe = false
                playerB.isSafe = false
                
                // Dá update no dicionário dos players
                playerNodes[nodeAName] = playerA
                playerNodes[nodeBName] = playerB
                print("\(nodeAName) ///// \(playerA.isSafe)")
                print("\(nodeBName) ///// \(playerB.isSafe)")
                checkGameEnd() // Checa a condição de fim de jogo
            }
        }
    }
    
    // MARK: -- FIM DE JOGO
    func checkGameEnd() {
        
        let notSafeCount = playerNodes.values.filter { !$0.isSafe }.count
        
        // Conta o número de pegos e o número total de jogadores
        if notSafeCount >= 2 && notSafeCount == playerNodes.count {
            resetGame()
        }
    }

    func resetGame() {
        for (_, player) in playerNodes {
            player.node.removeFromParent()
        }
        
        // Reseta o jogo
            playerNodes.removeAll()

            // Display Game Over Label
            gameOverLabel.isHidden = false
    }
}
