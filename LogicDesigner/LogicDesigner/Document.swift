//
//  Document.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 2/16/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit
import Logic

class Document: NSDocument {

    override init() {
        super.init()
    }

    override class var autosavesInPlace: Bool {
        return false
    }

    var window: NSWindow?

    let logicEditor = LogicEditor()
    let containerView = NSBox()

    override func makeWindowControllers() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false)

        containerView.boxType = .custom
        containerView.borderType = .noBorder
        containerView.contentViewMargins = .zero

        containerView.addSubview(logicEditor)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        logicEditor.translatesAutoresizingMaskIntoConstraints = false

        logicEditor.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        logicEditor.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive = true
        logicEditor.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive = true
        logicEditor.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive = true

        logicEditor.showsDropdown = true
//        logicEditor.rootNode = .topLevelParameters(
//            LGCTopLevelParameters(id: UUID(), parameters: .next(.placeholder(id: UUID()), .empty))
//        )

        let labelFont = TextStyle(family: "San Francisco", weight: .bold, size: 9).nsFont

        var annotations: [UUID: String] = [:]

        var alphaSubstitution: AlphaRenaming.Substitution = [:]
//        var unificationContext = Environment.UnificationContext()

        logicEditor.decorationForNodeID = { id in
            guard let node = self.logicEditor.rootNode.find(id: id) else { return nil }

            if let annotation = annotations[node.uuid] {
                return .label(labelFont, annotation)
            }

            switch node {
            case .literal(.color(id: _, value: _)):
                return .color(.red)
            case .identifier(let identifier) where identifier.string.starts(with: "TextStyles."):
                return .character(TextStyle(size: 18, color: .purple).apply(to: "S"), .purple)
            default:
                return nil
            }
        }

        logicEditor.suggestionsForNode = { [unowned self] node, query in
            Swift.print("---------")

            let rootNode = self.logicEditor.rootNode

            switch node {
            case .expression(let expression):
                do {
                    //                    let compilerContext = try Environment.compile(rootNode, in: .standard)

                    let alphaRenamingContext = AlphaRenaming.rename(rootNode)

                    Swift.print("Alpha sub", alphaRenamingContext)

//                    let namesInScope =
//                        Set(
//                            Environment.scope(rootNode, targetId: node.uuid).flattened.keys
//                                .compactMap { alphaRenamingContext.originalNames[$0] }
//                        )
//
//                    Swift.print("Scope", namesInScope)

                    guard case .success(let unificationContext) = Environment.makeConstraints(rootNode) else { return [] }

                    Swift.print("Unification context", unificationContext.constraints)

                    switch TypeEntity.unify(constraints: unificationContext.constraints) {
                    case .failure(let error):
                        Swift.print("Unification failed", error)
                        return []
                    case .success(let substitution):
                        Swift.print("Substitution", substitution)

                        guard var type = unificationContext.nodes[expression.uuid] else {
                            Swift.print("Can't determine suggestions - no type for expression", expression.uuid)
                            return []
                        }

                        Swift.print("Typename", type, "Substituted as", substitution[type])

                        if type.name.starts(with: "?") {
                            guard let substitutedType = substitution[type] else {
                                Swift.print("Can't determine suggestions - no type substitution", expression.uuid)
                                return []
                            }

                            type = substitutedType
                        }

                        if type.name == "Boolean" {
                            let namesInScope = Environment.scope(rootNode, targetId: node.uuid).flattened.keys

                            Swift.print("Scope", namesInScope)

                            let matchingIdentifiers: [String] = namesInScope.compactMap({ nodeId in
//                                let newName = alphaSubstitution[pair.value]

                                guard var type = unificationContext.nodes[nodeId] else { return nil }

                                if type.name.starts(with: "?") {
                                    guard let substitutedType = substitution[type] else { return nil }
                                    type = substitutedType
                                }

                                if type.name == "Boolean" {
                                    return alphaRenamingContext.originalNames[nodeId]
                                }

                                return nil
                            })

                            Swift.print("Matching ids", matchingIdentifiers)

                            let identifiers: [LogicSuggestionItem] = matchingIdentifiers.map { identifier in
                                LogicSuggestionItem(
                                    title: identifier,
                                    category: "Variables".uppercased(),
                                    node: LGCSyntaxNode.expression(
                                        .identifierExpression(id: UUID(), identifier: .init(id: UUID(), string: identifier))
                                    )
                                )
                            }

                            let literals: [LogicSuggestionItem] = [
                                LGCLiteral.Suggestion.true,
                                LGCLiteral.Suggestion.false
                            ].compactMap(LGCExpression.Suggestion.from(literalSuggestion:))

                            return (identifiers + literals).titleContains(prefix: query)
                        }

                        return []
                    }
                } catch let error {
                    Swift.print("Can't determine suggestions - compiler error", error)
                    return []
                }
            default:
                return LogicEditor.defaultSuggestionsForNode(node, self.logicEditor.rootNode, query)
            }
        }

        logicEditor.onChangeRootNode = { [unowned self] rootNode in
            self.logicEditor.rootNode = rootNode

            do {
                let alphaSubstitution = AlphaRenaming.rename(rootNode)
//                let context = try Environment.makeConstraints(rootNode, alphaSubstitution: alphaSubstitution)

//                unificationContext = context

//                Swift.print("Unification context", context)
            } catch let error {
                Swift.print("Unification failed")
            }

            do {
                let compilerContext = try Environment.compile(rootNode, in: .standard)

//                Swift.print(compilerContext.nodeType, compilerContext.scopes)

                let context = try Environment.evaluate(rootNode, in: .standard).1

//                Swift.print(context.scopes)

                annotations = context.annotations

                self.logicEditor.underlinedId = nil
            } catch let error {
                if let error = error as? CompilerError {
//                    Swift.print("Compiler error", error)

                    self.logicEditor.underlinedId = error.nodeId
                }

                if let error = error as? LogicError {
                    annotations = error.context.annotations
                    
                    self.logicEditor.underlinedId = error.nodeId
                }
            }

            return true
        }

        window.backgroundColor = Colors.background
        window.center()
        window.contentView = containerView

        self.window = window

        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        addWindowController(windowController)
    }

    override func data(ofType typeName: String) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        return try encoder.encode(logicEditor.rootNode)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        logicEditor.rootNode = try JSONDecoder().decode(LGCSyntaxNode.self, from: data)
    }
}

