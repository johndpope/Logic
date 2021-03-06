import AppKit
import Foundation

// MARK: - TextStyleRow

public class TextStyleRow: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(titleText: String, textStyle: TextStyle, selected: Bool, disabled: Bool) {
    self.init(Parameters(titleText: titleText, textStyle: textStyle, selected: selected, disabled: disabled))
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

  public var titleText: String {
    get { return parameters.titleText }
    set {
      if parameters.titleText != newValue {
        parameters.titleText = newValue
      }
    }
  }

  public var textStyle: TextStyle {
    get { return parameters.textStyle }
    set {
      if parameters.textStyle != newValue {
        parameters.textStyle = newValue
      }
    }
  }

  public var selected: Bool {
    get { return parameters.selected }
    set {
      if parameters.selected != newValue {
        parameters.selected = newValue
      }
    }
  }

  public var disabled: Bool {
    get { return parameters.disabled }
    set {
      if parameters.disabled != newValue {
        parameters.disabled = newValue
      }
    }
  }

  public var parameters: Parameters {
    didSet {
      if parameters != oldValue {
        update()
      }
    }
  }

  // MARK: Private

  private var detailsView = NSBox()
  private var textView = LNATextField(labelWithString: "")

  private var textViewTextStyle = TextStyles.row

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
    detailsView.boxType = .custom
    detailsView.borderType = .noBorder
    detailsView.contentViewMargins = .zero
    textView.lineBreakMode = .byWordWrapping

    addSubview(detailsView)
    detailsView.addSubview(textView)

    textView.maximumNumberOfLines = 1
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
    detailsView.translatesAutoresizingMaskIntoConstraints = false
    textView.translatesAutoresizingMaskIntoConstraints = false

    let detailsViewHeightAnchorParentConstraint = detailsView
      .heightAnchor
      .constraint(lessThanOrEqualTo: heightAnchor, constant: -8)
    let detailsViewLeadingAnchorConstraint = detailsView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12)
    let detailsViewTrailingAnchorConstraint = detailsView
      .trailingAnchor
      .constraint(equalTo: trailingAnchor, constant: -12)
    let detailsViewTopAnchorConstraint = detailsView.topAnchor.constraint(equalTo: topAnchor, constant: 4)
    let detailsViewBottomAnchorConstraint = detailsView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
    let textViewTopAnchorConstraint = textView.topAnchor.constraint(equalTo: detailsView.topAnchor)
    let textViewBottomAnchorConstraint = textView.bottomAnchor.constraint(equalTo: detailsView.bottomAnchor)
    let textViewLeadingAnchorConstraint = textView.leadingAnchor.constraint(equalTo: detailsView.leadingAnchor)
    let textViewTrailingAnchorConstraint = textView
      .trailingAnchor
      .constraint(lessThanOrEqualTo: detailsView.trailingAnchor)

    detailsViewHeightAnchorParentConstraint.priority = NSLayoutConstraint.Priority.defaultLow

    NSLayoutConstraint.activate([
      detailsViewHeightAnchorParentConstraint,
      detailsViewLeadingAnchorConstraint,
      detailsViewTrailingAnchorConstraint,
      detailsViewTopAnchorConstraint,
      detailsViewBottomAnchorConstraint,
      textViewTopAnchorConstraint,
      textViewBottomAnchorConstraint,
      textViewLeadingAnchorConstraint,
      textViewTrailingAnchorConstraint
    ])
  }

  private func update() {
    textView.attributedStringValue = textViewTextStyle.apply(to: titleText)
    textViewTextStyle = textStyle
    textView.attributedStringValue = textViewTextStyle.apply(to: textView.attributedStringValue)
  }
}

// MARK: - Parameters

extension TextStyleRow {
  public struct Parameters: Equatable {
    public var titleText: String
    public var textStyle: TextStyle
    public var selected: Bool
    public var disabled: Bool

    public init(titleText: String, textStyle: TextStyle, selected: Bool, disabled: Bool) {
      self.titleText = titleText
      self.textStyle = textStyle
      self.selected = selected
      self.disabled = disabled
    }

    public init() {
      self.init(titleText: "", textStyle: TextStyles.defaultStyle, selected: false, disabled: false)
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.titleText == rhs.titleText &&
        lhs.textStyle == rhs.textStyle && lhs.selected == rhs.selected && lhs.disabled == rhs.disabled
    }
  }
}

// MARK: - Model

extension TextStyleRow {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "TextStyleRow"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(titleText: String, textStyle: TextStyle, selected: Bool, disabled: Bool) {
      self.init(Parameters(titleText: titleText, textStyle: textStyle, selected: selected, disabled: disabled))
    }

    public init() {
      self.init(titleText: "", textStyle: TextStyles.defaultStyle, selected: false, disabled: false)
    }
  }
}
