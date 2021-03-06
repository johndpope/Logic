//
//  SwiftSyntax+Documentation.swift
//  LogicDesigner
//
//  Created by Devin Abbott on 3/3/19.
//  Copyright © 2019 BitDisco, Inc. All rights reserved.
//

import AppKit

public extension LGCExpression {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String) -> RichText {
        switch self {
        case .binaryExpression(let value):
            switch value.op {
            case .setEqualTo:
                let blocks: [RichText.BlockElement] = [
                    .heading(.title, "Assignment"),
                    .paragraph(
                        [
                            .text(
                                .none,
                                "Use an assignment expression to update the value of an existing variable."
                            )
                        ]
                    )
                ]

                return RichText(blocks: blocks)
            default:
                let blocks: [RichText.BlockElement] = [
                    .heading(.title, "Comparison"),
                    .paragraph(
                        [
                            .text(.none, "Compare two variables.")
                        ]
                    )
                ]

                return RichText(blocks: blocks)
            }
        default:
            return RichText(blocks: [])
        }
    }
}

public extension LGCFunctionParameter {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String) -> RichText {
        return RichText(
            blocks: [
                .alert(
                    .info,
                    .paragraph(
                        [
                            .text(.none, "Info message")
                        ]
                    )
                ),
                .heading(.title, "Title")
            ]
        )
    }
}

public extension LGCStatement {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String) -> RichText {
        switch self {
        case .branch:
            let example = LGCSyntaxNode.statement(
                LGCStatement.branch(
                    id: UUID(),
                    condition: LGCExpression.binaryExpression(
                        left: LGCExpression.identifierExpression(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "age")
                        ),
                        right: LGCExpression.identifierExpression(
                            id: UUID(),
                            identifier: LGCIdentifier(id: UUID(), string: "17")
                        ),
                        op: .isGreaterThan(id: UUID()),
                        id: UUID()
                    ),
                    block: LGCList<LGCStatement>.next(
                        LGCStatement.expressionStatement(
                            id: UUID(),
                            expression: LGCExpression.binaryExpression(
                                left: LGCExpression.identifierExpression(
                                    id: UUID(),
                                    identifier: LGCIdentifier(id: UUID(), string: "layers.Text.text")
                                ),
                                right: LGCExpression.identifierExpression(
                                    id: UUID(),
                                    identifier: LGCIdentifier(id: UUID(), string: "\"Congrats, you're an adult!\"")
                                ),
                                op: .setEqualTo(id: UUID()),
                                id: UUID()
                            )
                        ),
                        .empty
                    )
                )
            )

            let blocks: [RichText.BlockElement] = [
                .heading(.title, "If condition"),
                .paragraph(
                    [
                        .text(.none, "Conditions let you run different code depending on the current state of your app.")
                    ]
                ),
                .heading(.section, "Example"),
                .paragraph(
                    [
                        .text(.none, "Suppose our program has a variable "),
                        .text(.bold, "age"),
                        .text(.none, ", representing the current user's age. We might want to display a specific message depending on the value of age. We could use an "),
                        .text(.bold, "if condition "),
                        .text(.none, "to accomplish this:")
                    ]
                ),
                .custom(example.makeCodeView()),
//                .paragraph(
//                    [
//                        .text(.none) { "If we also wanted to print a message for users under 18, we might be better off using an " },
//                        .text(.link) { "if else statement" },
//                        .text(.none) { "." }
//                    ]
//                )
            ]

            return RichText(blocks: blocks)
        case .loop:
            let blocks: [RichText.BlockElement] = [
                .heading(.title, "For loop"),
                .paragraph(
                    [
                        .text(.none, "Loops let you run the same code multiple times, once for each item in a sequence of items.")
                    ]
                )
            ]

            return RichText(blocks: blocks)
        default:
            return RichText(blocks: [])
        }
    }
}

public extension LGCSyntaxNode {
    func documentation(within rootNode: LGCSyntaxNode, for prefix: String) -> RichText {
        return contents.documentation(within: rootNode, for: prefix)
    }

    func makeCodeView() -> NSView {
        let container = NSBox()
        container.boxType = .custom
        container.borderType = .lineBorder
        container.borderWidth = 1
        container.borderColor = NSColor(red: 0.59, green: 0.59, blue: 0.59, alpha: 0.26)
        container.fillColor = Colors.background
        container.cornerRadius = 4

        let editor = LogicCanvasView()
        editor.formattedContent = formatted

        container.addSubview(editor)

        editor.translatesAutoresizingMaskIntoConstraints = false
        editor.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        editor.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        editor.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        editor.bottomAnchor.constraint(equalTo: container.bottomAnchor).isActive = true

        return container
    }
}

