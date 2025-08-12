import Cocoa
import SpriteKit

class GraphVisualizationView: NSView {
    private var scene: GraphScene!
    private var skView: SKView!
    
    var onNodeSelected: ((GraphNode) -> Void)?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        skView = SKView(frame: bounds)
        skView.autoresizingMask = [.width, .height]
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.ignoresSiblingOrder = true
        skView.allowsTransparency = true
        
        addSubview(skView)
        
        scene = GraphScene(size: bounds.size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.onNodeSelected = { [weak self] node in
            self?.onNodeSelected?(node)
        }
        
        skView.presentScene(scene)
    }
    
    func loadGraph(from documents: [URL: MarkdownDocument], links: [URL: Set<WikiLinkParser.WikiLink>]) {
        scene.buildGraph(from: documents, links: links)
    }
    
    func highlightNode(for url: URL) {
        scene.highlightNode(for: url)
    }
    
    func setZoom(_ zoom: CGFloat) {
        scene.setScale(zoom)
    }
}

class GraphScene: SKScene {
    private var nodes: [URL: GraphNodeSprite] = [:]
    private var edges: [GraphEdgeSprite] = []
    private var centerNode: GraphNodeSprite?
    private var isDragging = false
    private var lastTouchLocation: CGPoint?
    
    var onNodeSelected: ((GraphNode) -> Void)?
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    }
    
    func buildGraph(from documents: [URL: MarkdownDocument], links: [URL: Set<WikiLinkParser.WikiLink>]) {
        removeAllChildren()
        nodes.removeAll()
        edges.removeAll()
        
        var nodePositions: [URL: CGPoint] = [:]
        let centerPoint = CGPoint(x: size.width / 2, y: size.height / 2)
        
        var angle: CGFloat = 0
        let angleIncrement = (2 * .pi) / CGFloat(documents.count)
        let radius: CGFloat = min(size.width, size.height) * 0.3
        
        for (url, document) in documents {
            let x = centerPoint.x + radius * cos(angle)
            let y = centerPoint.y + radius * sin(angle)
            let position = CGPoint(x: x, y: y)
            
            nodePositions[url] = position
            
            let node = createNode(for: document, at: position)
            nodes[url] = node
            addChild(node)
            
            angle += angleIncrement
        }
        
        for (sourceURL, wikiLinks) in links {
            guard let sourceNode = nodes[sourceURL] else { continue }
            
            for link in wikiLinks {
                if let targetPath = link.targetPath,
                   let targetURL = URL(string: "file://\(targetPath)"),
                   let targetNode = nodes[targetURL] {
                    
                    let edge = createEdge(from: sourceNode, to: targetNode)
                    edges.append(edge)
                    addChild(edge)
                }
            }
        }
        
        applyForceDirectedLayout()
    }
    
    private func createNode(for document: MarkdownDocument, at position: CGPoint) -> GraphNodeSprite {
        let node = GraphNodeSprite(document: document)
        node.position = position
        
        let physics = SKPhysicsBody(circleOfRadius: 30)
        physics.isDynamic = true
        physics.affectedByGravity = false
        physics.mass = 1.0
        physics.friction = 0.5
        physics.restitution = 0.3
        node.physicsBody = physics
        
        return node
    }
    
    private func createEdge(from source: GraphNodeSprite, to target: GraphNodeSprite) -> GraphEdgeSprite {
        return GraphEdgeSprite(from: source, to: target)
    }
    
    private func applyForceDirectedLayout() {
        let repulsionStrength: CGFloat = 5000
        let attractionStrength: CGFloat = 0.001
        let damping: CGFloat = 0.9
        
        let updateAction = SKAction.run { [weak self] in
            guard let self = self else { return }
            
            for (_, node) in self.nodes {
                var force = CGVector.zero
                
                for (_, otherNode) in self.nodes where node !== otherNode {
                    let dx = node.position.x - otherNode.position.x
                    let dy = node.position.y - otherNode.position.y
                    let distance = sqrt(dx * dx + dy * dy)
                    
                    if distance > 0 {
                        let repulsion = repulsionStrength / (distance * distance)
                        force.dx += (dx / distance) * repulsion
                        force.dy += (dy / distance) * repulsion
                    }
                }
                
                for edge in self.edges {
                    if edge.source === node || edge.target === node {
                        let other = edge.source === node ? edge.target : edge.source
                        let dx = other.position.x - node.position.x
                        let dy = other.position.y - node.position.y
                        let distance = sqrt(dx * dx + dy * dy)
                        
                        if distance > 0 {
                            force.dx += dx * attractionStrength
                            force.dy += dy * attractionStrength
                        }
                    }
                }
                
                let centerDx = self.size.width / 2 - node.position.x
                let centerDy = self.size.height / 2 - node.position.y
                force.dx += centerDx * 0.0001
                force.dy += centerDy * 0.0001
                
                node.physicsBody?.velocity.dx *= damping
                node.physicsBody?.velocity.dy *= damping
                
                node.physicsBody?.applyForce(force)
            }
            
            for edge in self.edges {
                edge.update()
            }
        }
        
        let waitAction = SKAction.wait(forDuration: 0.02)
        let sequence = SKAction.sequence([updateAction, waitAction])
        let repeatAction = SKAction.repeatForever(sequence)
        
        run(repeatAction, withKey: "forceDirectedLayout")
    }
    
    func highlightNode(for url: URL) {
        for (nodeURL, node) in nodes {
            if nodeURL == url {
                node.setHighlighted(true)
                centerNode = node
                
                let moveAction = SKAction.move(to: CGPoint(x: size.width / 2, y: size.height / 2), duration: 0.5)
                moveAction.timingMode = .easeInEaseOut
                node.run(moveAction)
            } else {
                node.setHighlighted(false)
            }
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        let location = event.location(in: self)
        let clickedNodes = nodes(at: location)
        
        if let nodeSprite = clickedNodes.first as? GraphNodeSprite {
            nodeSprite.graphNode.url.map { onNodeSelected?(GraphNode(url: $0, title: nodeSprite.graphNode.title)) }
            highlightNode(for: nodeSprite.graphNode.url!)
        }
        
        isDragging = true
        lastTouchLocation = location
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging, let lastLocation = lastTouchLocation else { return }
        
        let location = event.location(in: self)
        let dx = location.x - lastLocation.x
        let dy = location.y - lastLocation.y
        
        for (_, node) in nodes {
            node.position.x += dx
            node.position.y += dy
        }
        
        lastTouchLocation = location
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
        lastTouchLocation = nil
    }
    
    override func scrollWheel(with event: NSEvent) {
        let scale = 1.0 + (event.deltaY * 0.01)
        setScale(xScale * scale)
    }
}

class GraphNodeSprite: SKNode {
    let graphNode: GraphNode
    private let circle: SKShapeNode
    private let label: SKLabelNode
    
    init(document: MarkdownDocument) {
        self.graphNode = GraphNode(
            url: document.url,
            title: document.url?.deletingPathExtension().lastPathComponent ?? "Untitled"
        )
        
        circle = SKShapeNode(circleOfRadius: 30)
        circle.fillColor = NSColor.systemBlue
        circle.strokeColor = NSColor.systemBlue.withAlphaComponent(0.5)
        circle.lineWidth = 2
        
        label = SKLabelNode(text: graphNode.title)
        label.fontSize = 10
        label.fontName = NSFont.systemFont(ofSize: 10, weight: .medium).fontName
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        
        super.init()
        
        addChild(circle)
        addChild(label)
        
        let titleLabel = SKLabelNode(text: graphNode.title)
        titleLabel.fontSize = 12
        titleLabel.fontColor = NSColor.labelColor
        titleLabel.position = CGPoint(x: 0, y: -45)
        titleLabel.verticalAlignmentMode = .top
        titleLabel.horizontalAlignmentMode = .center
        addChild(titleLabel)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setHighlighted(_ highlighted: Bool) {
        if highlighted {
            circle.fillColor = NSColor.systemOrange
            circle.strokeColor = NSColor.systemOrange.withAlphaComponent(0.5)
            circle.setScale(1.2)
        } else {
            circle.fillColor = NSColor.systemBlue
            circle.strokeColor = NSColor.systemBlue.withAlphaComponent(0.5)
            circle.setScale(1.0)
        }
    }
}

class GraphEdgeSprite: SKNode {
    let source: GraphNodeSprite
    let target: GraphNodeSprite
    private let line: SKShapeNode
    
    init(from source: GraphNodeSprite, to target: GraphNodeSprite) {
        self.source = source
        self.target = target
        
        line = SKShapeNode()
        line.strokeColor = NSColor.tertiaryLabelColor
        line.lineWidth = 1
        line.alpha = 0.5
        
        super.init()
        
        addChild(line)
        update()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update() {
        let path = CGMutablePath()
        path.move(to: source.position)
        path.addLine(to: target.position)
        line.path = path
    }
}

struct GraphNode {
    let url: URL?
    let title: String
}