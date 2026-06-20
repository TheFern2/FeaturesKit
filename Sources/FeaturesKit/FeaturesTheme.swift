import SwiftUI

public struct FeaturesTheme: Sendable {
    public var accent: Color
    public var statusNew: Color
    public var statusUnderReview: Color
    public var statusPlanned: Color
    public var statusInProgress: Color
    public var statusShipped: Color
    public var statusDone: Color
    public var statusDeclined: Color

    public init(
        accent: Color = .accentColor,
        statusNew: Color = .secondary,
        statusUnderReview: Color = .orange,
        statusPlanned: Color = .blue,
        statusInProgress: Color = .purple,
        statusShipped: Color = .green,
        statusDone: Color = .green,
        statusDeclined: Color = .red
    ) {
        self.accent = accent
        self.statusNew = statusNew
        self.statusUnderReview = statusUnderReview
        self.statusPlanned = statusPlanned
        self.statusInProgress = statusInProgress
        self.statusShipped = statusShipped
        self.statusDone = statusDone
        self.statusDeclined = statusDeclined
    }

    func statusColor(_ status: RequestStatus) -> Color {
        switch status {
        case .new: statusNew
        case .underReview: statusUnderReview
        case .planned: statusPlanned
        case .inProgress: statusInProgress
        case .shipped: statusShipped
        case .done: statusDone
        case .declined: statusDeclined
        }
    }
}

struct FeaturesThemeKey: EnvironmentKey {
    static let defaultValue = FeaturesTheme()
}

extension EnvironmentValues {
    var featuresTheme: FeaturesTheme {
        get { self[FeaturesThemeKey.self] }
        set { self[FeaturesThemeKey.self] = newValue }
    }
}
