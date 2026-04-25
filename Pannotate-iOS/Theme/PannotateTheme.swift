import SwiftUI
import UIKit

enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            "Light"
        case .dark:
            "Dark"
        case .system:
            "System"
        }
    }

    var systemImage: String {
        switch self {
        case .light:
            "sun.max"
        case .dark:
            "moon"
        case .system:
            "desktopcomputer"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            .light
        case .dark:
            .dark
        case .system:
            nil
        }
    }
}

enum PannotateTheme {
    enum Colors {
        static let background = adaptive(
            light: UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0),
            dark: UIColor(red: 0.02, green: 0.02, blue: 0.03, alpha: 1.0)
        )
        static let elevated = adaptive(
            light: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 0.96),
            dark: UIColor(red: 0.07, green: 0.07, blue: 0.08, alpha: 1.0)
        )
        static let card = adaptive(
            light: UIColor(red: 1.00, green: 1.00, blue: 1.00, alpha: 1.0),
            dark: UIColor(red: 0.09, green: 0.09, blue: 0.10, alpha: 1.0)
        )
        static let cardMuted = adaptive(
            light: UIColor(red: 0.92, green: 0.94, blue: 0.98, alpha: 1.0),
            dark: UIColor(red: 0.13, green: 0.13, blue: 0.15, alpha: 1.0)
        )
        static let outputInfoPanel = adaptive(
            light: UIColor(red: 0.98, green: 0.99, blue: 1.00, alpha: 1.0),
            dark: UIColor(red: 0.045, green: 0.045, blue: 0.055, alpha: 1.0)
        )
        static let outputSecondaryButton = adaptive(
            light: UIColor(red: 0.90, green: 0.93, blue: 0.98, alpha: 1.0),
            dark: UIColor.white.withAlphaComponent(0.12)
        )
        static let primaryText = adaptive(
            light: UIColor(red: 0.07, green: 0.08, blue: 0.11, alpha: 1.0),
            dark: UIColor.white
        )
        static let secondaryText = adaptive(
            light: UIColor(red: 0.36, green: 0.38, blue: 0.45, alpha: 1.0),
            dark: UIColor(red: 0.63, green: 0.62, blue: 0.68, alpha: 1.0)
        )
        static let tertiaryText = adaptive(
            light: UIColor(red: 0.56, green: 0.58, blue: 0.66, alpha: 1.0),
            dark: UIColor(red: 0.42, green: 0.41, blue: 0.47, alpha: 1.0)
        )
        static let border = adaptive(
            light: UIColor(red: 0.10, green: 0.13, blue: 0.18, alpha: 0.10),
            dark: UIColor.white.withAlphaComponent(0.10)
        )
        static let accent = Color(red: 0.20, green: 0.54, blue: 1.00)
        static let accentSoft = adaptive(
            light: UIColor(red: 0.84, green: 0.91, blue: 1.00, alpha: 1.0),
            dark: UIColor(red: 0.10, green: 0.27, blue: 0.52, alpha: 1.0)
        )
        static let success = Color(red: 0.12, green: 0.84, blue: 0.42)
        static let purple = Color(red: 0.39, green: 0.22, blue: 0.93)

        private static func adaptive(light: UIColor, dark: UIColor) -> Color {
            Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? dark : light
            })
        }
    }

    enum Metrics {
        static let pagePadding: CGFloat = 18
        static let cardRadius: CGFloat = 22
        static let controlRadius: CGFloat = 16
        static let tabBarContentInset: CGFloat = 36
        static let sequenceThumbnailSize = CGSize(width: 72, height: 50)
    }

    static let brandGradient = LinearGradient(
        colors: [Colors.accent, Colors.purple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [Colors.accentSoft.opacity(0.95), Colors.purple.opacity(0.22)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct PannotateCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(PannotateTheme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.cardRadius, style: .continuous)
                    .stroke(PannotateTheme.Colors.border, lineWidth: 1)
            )
    }
}

extension View {
    func pannotateCard() -> some View {
        modifier(PannotateCardStyle())
    }

    func pannotatePage() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
    }
}
