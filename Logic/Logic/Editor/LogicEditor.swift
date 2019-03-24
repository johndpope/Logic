import AppKit

public let defaultRootNode = LGCSyntaxNode.program(
    LGCProgram(
        id: UUID(),
        block: LGCList<LGCStatement>.next(
            LGCStatement.placeholderStatement(id: UUID()),
            .empty
        )
    )
)

// MARK: - LogicEditor

public class LogicEditor: NSBox {

    // MARK: Lifecycle

    public init(rootNode: LGCSyntaxNode = defaultRootNode) {
        self.rootNode = rootNode

        super.init(frame: .zero)

        setUpViews()
        setUpConstraints()

        update()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Public

    public var rootNode: LGCSyntaxNode {
        didSet {
            canvasView.formattedContent = rootNode.formatted
        }
    }

    // MARK: Private

    private var suggestionText: String = "" {
        didSet {
            childWindow?.suggestionText = suggestionText
        }
    }

    private var selectedSuggestionIndex: Int? {
        didSet {
            childWindow?.selectedIndex = selectedSuggestionIndex
        }
    }

    private lazy var childWindow: SuggestionWindow? = SuggestionWindow()

    private let canvasView = LogicCanvasView()
    private let scrollView = NSScrollView()

    private func setUpViews() {
        boxType = .custom
        borderType = .noBorder
        contentViewMargins = .zero

        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = false
        scrollView.documentView = canvasView

        addSubview(scrollView)

        canvasView.formattedContent = rootNode.formatted
        canvasView.onActivate = handleActivateElement
        canvasView.onActivateLine = handleActivateLine
        canvasView.onPressTabKey = nextNode
        canvasView.onPressShiftTabKey = previousNode
    }

    private func setUpConstraints() {
        translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        canvasView.translatesAutoresizingMaskIntoConstraints = false

        canvasView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        canvasView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true

        scrollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }

    private func update() {}
}

// MARK: - Selection

extension LogicEditor {

    private func nextNode() {
        if let index = rootNode.formatted.nextActivatableElementIndex(after: self.canvasView.selectedRange?.lowerBound),
            let id = self.rootNode.formatted.elements[index].syntaxNodeID {

            self.canvasView.selectedRange = self.rootNode.elementRange(for: id)
            self.suggestionText = ""

            let nextSyntaxNode = self.rootNode.topNodeWithEqualElements(as: id)
            self.showSuggestionWindow(for: index, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No next node to activate")

            self.hideSuggestionWindow()
        }
    }

    private func previousNode() {
        if let index = rootNode.formatted.previousActivatableElementIndex(before: self.canvasView.selectedRange?.lowerBound),
            let id = self.rootNode.formatted.elements[index].syntaxNodeID {

            self.canvasView.selectedRange = self.rootNode.elementRange(for: id)
            self.suggestionText = ""

            let nextSyntaxNode = self.rootNode.topNodeWithEqualElements(as: id)
            self.showSuggestionWindow(for: index, syntaxNode: nextSyntaxNode)
        } else {
            Swift.print("No previous node to activate")

            self.hideSuggestionWindow()
        }
    }

    private func select(nodeByID syntaxNodeId: UUID?) {
        self.canvasView.selectedLine = nil
        self.suggestionText = ""

        if let syntaxNodeId = syntaxNodeId {
            let topNode = self.rootNode.topNodeWithEqualElements(as: syntaxNodeId)

            if let selectedRange = self.rootNode.elementRange(for: topNode.uuid) {
                self.canvasView.selectedRange = selectedRange
                self.showSuggestionWindow(for: selectedRange.lowerBound, syntaxNode: topNode)
            } else {
                self.canvasView.selectedRange = nil
                self.hideSuggestionWindow()
            }
        } else {
            self.canvasView.selectedRange = nil
            self.hideSuggestionWindow()
        }
    }

    private func handleActivateElement(_ activatedIndex: Int?) {
        if let activatedIndex = activatedIndex {
            let id = self.rootNode.formatted.elements[activatedIndex].syntaxNodeID
            self.select(nodeByID: id)
        } else {
            self.select(nodeByID: nil)
        }
    }

    private func handleActivateLine(_ activatedLineIndex: Int) {
        handleActivateElement(nil)

        canvasView.selectedLine = activatedLineIndex
    }
}

// MARK: - Suggestions

extension LogicEditor {

    private func indexedSuggestionListItems(for logicSuggestionItems: [LogicSuggestionItem]) -> [(offset: Int, item: SuggestionListItem)] {
        var categories: [(name: String, list: [(offset: Int, item: LogicSuggestionItem)])] = []

        logicSuggestionItems.enumerated().forEach { offset, item in
            if let categoryIndex = categories.firstIndex(where: { $0.name == item.category }) {
                let category = categories[categoryIndex]
                categories[categoryIndex] = (category.name, category.list + [(offset, item)])
            } else {
                categories.append((item.category, [(offset, item)]))
            }
        }

        var suggestionListItems: [(Int, SuggestionListItem)] = []

        categories.forEach { category in
            suggestionListItems.append((0, .sectionHeader(category.name)))

            category.list.forEach { logicItem in
                suggestionListItems.append((logicItem.offset, .row(logicItem.item.title, logicItem.item.disabled)))
            }
        }

        return suggestionListItems
    }

    private func logicSuggestionItems(for syntaxNode: LGCSyntaxNode, prefix: String) -> [LogicSuggestionItem] {
        guard let range = rootNode.elementRange(for: syntaxNode.uuid),
            let elementPath = rootNode.pathTo(id: syntaxNode.uuid) else { return [] }

        let highestMatch = elementPath.first(where: { rootNode.elementRange(for: $0.uuid) == range }) ?? syntaxNode

        return highestMatch.suggestions(for: prefix)
    }
}

// MARK: - Suggestion Window

extension LogicEditor {

    private func showSuggestionWindow(for nodeIndex: Int, syntaxNode: LGCSyntaxNode) {
        guard let window = self.window, let childWindow = self.childWindow else { return }

        let syntaxNodePath = self.rootNode.uniqueElementPathTo(id: syntaxNode.uuid)
        let dropdownNodes = Array(syntaxNodePath)

        var logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: suggestionText)

        let originalIndexedSuggestions = indexedSuggestionListItems(for: logicSuggestions)
        childWindow.detailView = logicSuggestions.first?.node.documentation(for: suggestionText).makeScrollView()
        childWindow.suggestionItems = originalIndexedSuggestions.map { $0.item }
        childWindow.selectedIndex = originalIndexedSuggestions.firstIndex { $0.item.isSelectable }
        childWindow.dropdownValues = dropdownNodes.map { $0.nodeTypeDescription }
        childWindow.dropdownIndex = dropdownNodes.count - 1

        childWindow.onSelectIndex = { index in
            self.selectedSuggestionIndex = index

            if let index = index {
                let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
                let suggestedNode = logicSuggestions[indexedSuggestions[index].offset].node

                childWindow.detailView = suggestedNode.documentation(for: self.suggestionText).makeScrollView()
            } else {
                childWindow.detailView = nil
            }
        }

        childWindow.onPressEscapeKey = {
            self.hideSuggestionWindow()
        }

        childWindow.onPressTabKey = self.nextNode

        childWindow.onPressShiftTabKey = self.previousNode

        childWindow.onHighlightDropdownIndex = { highlightedIndex in
            if let highlightedIndex = highlightedIndex {
                let selected = dropdownNodes[highlightedIndex]
                let range = self.rootNode.elementRange(for: selected.uuid)

                self.canvasView.outlinedRange = range
            } else {
                self.canvasView.outlinedRange = nil
            }
        }

        childWindow.onSelectDropdownIndex = { selectedIndex in
            self.canvasView.outlinedRange = nil
            self.select(nodeByID: dropdownNodes[selectedIndex].uuid)
        }

        childWindow.onSubmit = { index in
            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
            let logicSuggestionItem = logicSuggestions[indexedSuggestions[index].offset]

            if logicSuggestionItem.disabled { return }

            let suggestedNode = logicSuggestionItem.node

            Swift.print("Chose suggestion", suggestedNode)

            let replacement = self.rootNode.replace(id: syntaxNode.uuid, with: suggestedNode)

            self.rootNode = replacement

            if suggestedNode.movementAfterInsertion == .next {
                self.nextNode()
            } else {
                self.handleActivateElement(self.canvasView.selectedRange?.lowerBound)
            }
        }

        childWindow.onChangeSuggestionText = { value in
            self.suggestionText = value

            // Update logicSuggestions
            logicSuggestions = self.logicSuggestionItems(for: syntaxNode, prefix: value)

            let indexedSuggestions = self.indexedSuggestionListItems(for: logicSuggestions)
            childWindow.suggestionItems = indexedSuggestions.map { $0.item }
            childWindow.selectedIndex = indexedSuggestions.firstIndex(where: { $0.item.isSelectable })
        }

        window.addChildWindow(childWindow, ordered: .above)

        if let elementRect = canvasView.getElementRect(for: nodeIndex) {
            let windowRect = canvasView.convert(elementRect, to: nil)
            let screenRect = window.convertToScreen(windowRect)

            childWindow.anchorTo(rect: screenRect)
            childWindow.focusSearchField()
        }
    }

    private func hideSuggestionWindow() {
        guard let window = self.window, let childWindow = self.childWindow else { return }

        window.removeChildWindow(childWindow)
        childWindow.setIsVisible(false)
    }
}