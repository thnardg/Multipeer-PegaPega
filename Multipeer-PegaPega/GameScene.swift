import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - VARIÁVEIS
    let multipeerService = MultipeerService()
    var playerNodes: [String: SKSpriteNode] = [:]
    let playerSpacing: CGFloat = 100 //espaçamento inicial entre os players (temporário)
    var startButton: SKSpriteNode?
    var gameStarted: Bool = false
    var playersToAdd: [(peerID: String, color: UIColor)] = []

    // MARK: - DID MOVE
    override func didMove(to view: SKView) {
        self.backgroundColor = .white
        self.physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        self.physicsWorld.contactDelegate = self
        
        startButton = SKSpriteNode(color: .gray, size: CGSize(width: 100, height: 50))
                startButton?.position = CGPoint(x: self.frame.midX, y: self.frame.midY - 100)
                startButton?.name = "startButton"
                self.addChild(startButton!)
    }

    // MARK: - TOUCHES ENDED
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        if let node = self.atPoint(location) as? SKSpriteNode, node.name == "startButton" {
            setupGame()
        }
    }
    
    // MARK: - ADD JOGADORES
    func addPlayer(forPeer peerID: String, color: UIColor) {
            if gameStarted {
                let newPlayer = NewPlayer(color: color, size: CGSize(width: 50, height: 50))
                let numberOfPlayers = playerNodes.count
                let xOffset = CGFloat(numberOfPlayers) * playerSpacing
                newPlayer.position = CGPoint(x: self.frame.midX + xOffset, y: self.frame.midY)

                self.addChild(newPlayer)

                newPlayer.physicsBody = SKPhysicsBody(rectangleOf: newPlayer.size)
                newPlayer.physicsBody?.isDynamic = true
                newPlayer.physicsBody?.allowsRotation = false
                newPlayer.physicsBody?.affectedByGravity = false
                newPlayer.physicsBody?.categoryBitMask = 1
                newPlayer.physicsBody?.contactTestBitMask = 1
                newPlayer.physicsBody?.collisionBitMask = 1

                playerNodes[peerID] = newPlayer
            } else {
                playersToAdd.append((peerID: peerID, color: color))
            }
        }
    
    // MARK: - SETUP GAME
    func setupGame() {
            startButton?.removeFromParent()
            gameStarted = true

            for playerInfo in playersToAdd {
                addPlayer(forPeer: playerInfo.peerID, 
                          color: playerInfo.color)
            }

            playersToAdd.removeAll()
        }
    
    // MARK: - MOVIMENTAÇÃO
    func moveNode(forPeer peerID: String, to position: CGPoint) {
            playerNodes[peerID]?.run(SKAction.move(to: position, duration: 0.1))
        }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
           if let touch = touches.first {
               let location = touch.location(in: self)

               let positionString = "\(location.x),\(location.y)"
               multipeerService.send(position: positionString)
           }
       }
}

// Classe player
class NewPlayer: SKSpriteNode {
    var safe: Bool = true
}
