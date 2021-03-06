import AppKit
import Foundation

// MARK: - SuggestionDetailView

public class SuggestionDetailView: NSBox {

  // MARK: Lifecycle

  public init(_ parameters: Parameters) {
    self.parameters = parameters

    super.init(frame: .zero)

    setUpViews()
    setUpConstraints()

    update()
  }

  public convenience init(detailView: CustomDetailView) {
    self.init(Parameters(detailView: detailView))
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

  public var detailView: CustomDetailView {
    get { return parameters.detailView }
    set {
      if parameters.detailView != newValue {
        parameters.detailView = newValue
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

  private func setUpViews() {
    boxType = .custom
    borderType = .noBorder
    contentViewMargins = .zero
  }

  private func setUpConstraints() {
    translatesAutoresizingMaskIntoConstraints = false
  }

  private func update() {}
}

// MARK: - Parameters

extension SuggestionDetailView {
  public struct Parameters: Equatable {
    public var detailView: CustomDetailView

    public init(detailView: CustomDetailView) {
      self.detailView = detailView
    }

    public init() {
      self.init(detailView: nil)
    }

    public static func ==(lhs: Parameters, rhs: Parameters) -> Bool {
      return lhs.detailView == rhs.detailView
    }
  }
}

// MARK: - Model

extension SuggestionDetailView {
  public struct Model: LonaViewModel, Equatable {
    public var id: String?
    public var parameters: Parameters
    public var type: String {
      return "SuggestionDetailView"
    }

    public init(id: String? = nil, parameters: Parameters) {
      self.id = id
      self.parameters = parameters
    }

    public init(_ parameters: Parameters) {
      self.parameters = parameters
    }

    public init(detailView: CustomDetailView) {
      self.init(Parameters(detailView: detailView))
    }

    public init() {
      self.init(detailView: nil)
    }
  }
}
