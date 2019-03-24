import AppKit
import Foundation

// MARK: - ControlledDropdown

public class ControlledDropdown: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(selectedIndex: Int, values: [String]) {
    self.init(Parameters(selectedIndex: selectedIndex, values: values))
  }

  public convenience init() {
    self.init(Parameters())
  }

  public required init?(coder aDecoder: NSCoder) {
    self.parameters = Parameters()

    super.init(coder: aDecoder)

    setUpViews()
    setUpConstraints()

    update()
  }

  // MARK: Public

  public var selectedIndex: Int {
    get { return parameters.selectedIndex }
    set {
      if parameters.selectedIndex != newValue {
        parameters.selectedIndex = newValue
      }
    }
  }

  public var onChangeIndex: ((Int) -> Void)? {
    get { return parameters.onChangeIndex }
    set { parameters.onChangeIndex = newValue }
  }

  public var onHighlightIndex: ((Int?) -> Void)? {
    get { return parameters.onHighlightIndex }
    set { parameters.onHighlightIndex = newValue }
  }

  public var values: [String] {
    get { return parameters.values }
    set {
      if parameters.values != newValue {
        parameters.values = newValue
      }
    }
  }

  public var onCloseMenu: (() -> Void)? {
    get { return parameters.onCloseMenu }
    set { parameters.onCloseMenu = newValue }
  }

  public var onOpenMenu: (() -> Void)? {
    get { return parameters.onOpenMenu }
    set { parameters.onOpenMenu = newValue }
  }

  public var parameters: Parameters {
    didSet {
      if parameters != oldValue {
        update()
      }
    }
  }

  // MARK: Private

  private var view1View = NSBox()
  private var textView = LNATextField(labelWithString: "")
  private var view2View = NSBox()

  private var textViewTextStyle = TextStyles.defaultStyle

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    view1View.boxType = .custom
    view1View.borderType = .noBorder
    view1View.contentViewMargins = .zero
    view2View.boxType = .custom
    view2View.borderType = .noBorder
    view2View.contentViewMargins = .zero
    textView.lineBreakMode = .byWordWrapping

    addSubview(view1View)
    addSubview(view2View)
    view1View.addSubview(textView)

    fillColor = Colors.divider
    textView.attributedStringValue = textViewTextStyle.apply(to: "Dropdown")
    view2View.fillColor = Colors.editableText
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    view1View.translatesAutoresizingMaskIntoConstraints = false
    view2View.translatesAutoresizingMaskIntoConstraints = false
    textView.translatesAutoresizingMaskIntoConstraints = false

    let view1ViewHeightAnchorParentConstraint = view1View.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
    let view2ViewHeightAnchorParentConstraint = view2View.heightAnchor.constraint(lessThanOrEqualTo: heightAnchor)
    let view1ViewLeadingAnchorConstraint = view1View.leadingAnchor.constraint(equalTo: leadingAnchor)
    let view1ViewTopAnchorConstraint = view1View.topAnchor.constraint(equalTo: topAnchor)
    let view2ViewTrailingAnchorConstraint = view2View.trailingAnchor.constraint(equalTo: trailingAnchor)
    let view2ViewLeadingAnchorConstraint = view2View.leadingAnchor.constraint(equalTo: view1View.trailingAnchor)
    let view2ViewTopAnchorConstraint = view2View.topAnchor.constraint(equalTo: topAnchor)
    let view2ViewBottomAnchorConstraint = view2View.bottomAnchor.constraint(equalTo: bottomAnchor)
    let view1ViewHeightAnchorConstraint = view1View.heightAnchor.constraint(equalToConstant: 22)
    let textViewTopAnchorConstraint = textView.topAnchor.constraint(equalTo: view1View.topAnchor)
    let textViewLeadingAnchorConstraint = textView
      .leadingAnchor
      .constraint(equalTo: view1View.leadingAnchor, constant: 8)
    let textViewTrailingAnchorConstraint = textView
      .trailingAnchor
      .constraint(lessThanOrEqualTo: view1View.trailingAnchor, constant: -8)
    let view2ViewWidthAnchorConstraint = view2View.widthAnchor.constraint(equalToConstant: 40)

    view1ViewHeightAnchorParentConstraint.priority = NSLayoutConstraint.Priority.defaultLow
    view2ViewHeightAnchorParentConstraint.priority = NSLayoutConstraint.Priority.defaultLow

    NSLayoutConstraint.activate([
      view1ViewHeightAnchorParentConstraint,
      view2ViewHeightAnchorParentConstraint,
      view1ViewLeadingAnchorConstraint,
      view1ViewTopAnchorConstraint,
      view2ViewTrailingAnchorConstraint,
      view2ViewLeadingAnchorConstraint,
      view2ViewTopAnchorConstraint,
      view2ViewBottomAnchorConstraint,
      view1ViewHeightAnchorConstraint,
      textViewTopAnchorConstraint,
      textViewLeadingAnchorConstraint,
      textViewTrailingAnchorConstraint,
      view2ViewWidthAnchorConstraint
    ])
  }

  private func update() {}

  private func handleOnChangeIndex(_ arg0: Int) {
    onChangeIndex?(arg0)
  }

  private func handleOnHighlightIndex(_ arg0: Int?) {
    onHighlightIndex?(arg0)
  }

  private func handleOnCloseMenu() {
    onCloseMenu?()
  }

  private func handleOnOpenMenu() {
    onOpenMenu?()
  }
}

// MARK: - Parameters

extension ControlledDropdown {
  public struct Parameters: Equatable {
    public var selectedIndex: Int
    public var values: [String]
    public var onChangeIndex: ((Int) -> Void)?
    public var onHighlightIndex: ((Int?) -> Void)?
    public var onCloseMenu: (() -> Void)?
    public var onOpenMenu: (() -> Void)?

    public init(
      selectedIndex: Int,
      values: [String],
      onChangeIndex: ((Int) -> Void)? = nil,
      onHighlightIndex: ((Int?) -> Void)? = nil,
      onCloseMenu: (() -> Void)? = nil,
      onOpenMenu: (() -> Void)? = nil)
    {
      self.selectedIndex = selectedIndex
      self.values = values
      self.onChangeIndex = onChangeIndex
      self.onHighlightIndex = onHighlightIndex
      self.onCloseMenu = onCloseMenu
      self.onOpenMenu = onOpenMenu
    }

    public init() {
      self.init(selectedIndex: 0, values: [])
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.selectedIndex == rhs.selectedIndex && lhs.values == rhs.values
    }
  }
}

// MARK: - Model

extension ControlledDropdown {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "ControlledDropdown"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(
      selectedIndex: Int,
      values: [String],
      onChangeIndex: ((Int) -> Void)? = nil,
      onHighlightIndex: ((Int?) -> Void)? = nil,
      onCloseMenu: (() -> Void)? = nil,
      onOpenMenu: (() -> Void)? = nil)
    {
      self
        .init(
          Parameters(
            selectedIndex: selectedIndex,
            values: values,
            onChangeIndex: onChangeIndex,
            onHighlightIndex: onHighlightIndex,
            onCloseMenu: onCloseMenu,
            onOpenMenu: onOpenMenu))
    }

    public init() {
      self.init(selectedIndex: 0, values: [])
    }
  }
}