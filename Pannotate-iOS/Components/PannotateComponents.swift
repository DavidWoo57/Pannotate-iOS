import SwiftUI
import UIKit

enum L10n {
    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key))
    }
}

struct BrandHeader: View {
    var trailingSystemImage: String?

    var body: some View {
        HStack {
            HStack(spacing: 10) {
                BrandMark(size: 34)
                Text("app.name")
                    .font(PannotateTheme.Typography.sectionTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
            }

            Spacer()

            if let trailingSystemImage {
                Image(systemName: trailingSystemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .frame(width: 42, height: 42)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(PannotateTheme.Colors.border, lineWidth: 1))
            }
        }
    }
}

struct BrandMark: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
                .fill(PannotateTheme.brandGradient)

            Image(systemName: "bolt")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
    }
}

struct PageTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(PannotateTheme.Typography.pageTitle)
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            if let subtitle {
                Text(subtitle)
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(PannotateTheme.Typography.label)
            .tracking(1.4)
            .foregroundStyle(PannotateTheme.Colors.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryActionButton: View {
    let title: String
    let systemImage: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(PannotateTheme.Typography.control)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: PannotateTheme.Metrics.buttonHeight)
                .background(PannotateTheme.Colors.accent)
                .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                .shadow(color: PannotateTheme.Colors.accent.opacity(0.32), radius: 18, y: 8)
        }
        .buttonStyle(.plain)
    }
}

struct SecondaryActionButton: View {
    let title: String
    let systemImage: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(PannotateTheme.Typography.control)
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: PannotateTheme.Metrics.buttonHeight)
                .background(PannotateTheme.Colors.cardMuted)
                .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                        .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct FixedHeaderPage<Header: View, Content: View>: View {
    var bottomPadding: CGFloat = PannotateTheme.Metrics.tabBarContentInset
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 14) {
                header()
            }
            .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .frame(maxWidth: .infinity)
            .background(PannotateTheme.Colors.background.opacity(0.96))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(PannotateTheme.Colors.border)
                    .frame(height: 1)
            }

            ScrollView {
                VStack(spacing: 16) {
                    content()
                }
                .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
                .padding(.top, 16)
                .padding(.bottom, bottomPadding)
            }
        }
        .pannotatePage()
    }
}

struct MockThumbnail: View {
    let style: ThumbnailStyle
    var cornerRadius: CGFloat = 18

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)

            if style == .city || style == .lights {
                SkylineShape()
                    .fill(Color.black.opacity(0.25))
                    .padding(.top, 26)
            }

            if style == .forest {
                HStack(spacing: 8) {
                    ForEach(0..<6) { _ in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.black.opacity(0.28))
                            .frame(width: 12)
                    }
                }
                .padding(.top, 12)
            }

            if style == .ocean {
                WaveShape()
                    .fill(Color.white.opacity(0.46))
                    .offset(x: -18, y: -2)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var colors: [Color] {
        switch style {
        case .city:
            [Color(red: 0.48, green: 0.76, blue: 0.98), Color(red: 0.92, green: 0.56, blue: 0.72), Color(red: 0.06, green: 0.11, blue: 0.20)]
        case .ocean:
            [Color(red: 0.86, green: 0.89, blue: 0.84), Color(red: 0.03, green: 0.54, blue: 0.62), Color(red: 0.00, green: 0.17, blue: 0.28)]
        case .forest:
            [Color(red: 0.74, green: 0.65, blue: 0.34), Color(red: 0.12, green: 0.35, blue: 0.17), Color(red: 0.04, green: 0.08, blue: 0.07)]
        case .lights:
            [Color(red: 0.06, green: 0.07, blue: 0.22), Color(red: 0.34, green: 0.22, blue: 0.74), Color(red: 0.03, green: 0.03, blue: 0.06)]
        }
    }
}

struct FixedClipThumbnail: View {
    let style: ThumbnailStyle
    var image: UIImage?
    var cornerRadius: CGFloat = 16

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    MockThumbnail(style: style, cornerRadius: cornerRadius)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .frame(width: PannotateTheme.Metrics.sequenceThumbnailSize.width, height: PannotateTheme.Metrics.sequenceThumbnailSize.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }
}

struct FixedMockThumbnail: View {
    let style: ThumbnailStyle
    let size: CGSize
    var cornerRadius: CGFloat

    var body: some View {
        GeometryReader { geometry in
            MockThumbnail(style: style, cornerRadius: cornerRadius)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .frame(width: size.width, height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }
}

struct CurrentProjectBanner: View {
    let prefix: String
    let project: Project

    var body: some View {
        HStack(spacing: 12) {
            FixedMockThumbnail(
                style: project.thumbnail,
                size: CGSize(width: 54, height: 40),
                cornerRadius: 12
            )

            VStack(alignment: .leading, spacing: 3) {
                Text("\(prefix): \(project.title)")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.primaryText)
                    .lineLimit(1)

                Text("common.current_project")
                    .font(PannotateTheme.Typography.label)
                    .foregroundStyle(PannotateTheme.Colors.accent)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
        }
        .padding(10)
        .background(PannotateTheme.Colors.cardMuted)
        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                .stroke(PannotateTheme.Colors.accent.opacity(0.32), lineWidth: 1)
        )
    }
}

struct ProjectRequiredEmptyState: View {
    let title: String
    let message: String
    let buttonTitle: String
    var action: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(PannotateTheme.Colors.accent)
                .frame(width: 92, height: 92)
                .background(PannotateTheme.Colors.accentSoft.opacity(0.62))
                .clipShape(Circle())

            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)
                .multilineTextAlignment(.center)

            Text(message)
                .font(PannotateTheme.Typography.body)
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
                .multilineTextAlignment(.center)

            PrimaryActionButton(title: buttonTitle, systemImage: "folder") {
                action()
            }

            Spacer()
        }
        .padding(PannotateTheme.Metrics.pagePadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PannotateTheme.Colors.background)
    }
}

struct ManagementRenameSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String

    let title: String
    let placeholder: String
    let onSave: (String) -> Void

    init(title: String, placeholder: String, initialName: String, onSave: @escaping (String) -> Void) {
        self.title = title
        self.placeholder = placeholder
        self.onSave = onSave
        _name = State(initialValue: initialName)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("common.name")
                    .font(PannotateTheme.Typography.cardTitle)
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)

                TextField(placeholder, text: $name)
                    .font(.headline)
                    .textInputAutocapitalization(.words)
                    .padding(16)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                            .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                    )

                Text("common.local_prototype_state_note")
                    .font(PannotateTheme.Typography.metadata)
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)

                Spacer()
            }
            .padding(PannotateTheme.Metrics.pagePadding)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        onSave(name)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct SkylineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let baseline = rect.maxY
        let widths = [0.08, 0.10, 0.07, 0.13, 0.09, 0.11, 0.08, 0.12]
        var currentX = rect.minX

        path.move(to: CGPoint(x: rect.minX, y: baseline))

        for (index, widthRatio) in widths.enumerated() {
            let width = rect.width * widthRatio
            let height = rect.height * CGFloat([0.36, 0.50, 0.42, 0.78, 0.52, 0.46, 0.64, 0.40][index])
            path.addLine(to: CGPoint(x: currentX, y: baseline - height))
            path.addLine(to: CGPoint(x: currentX + width, y: baseline - height))
            path.addLine(to: CGPoint(x: currentX + width, y: baseline))
            currentX += width + rect.width * 0.025
        }

        path.addLine(to: CGPoint(x: rect.maxX, y: baseline))
        path.closeSubpath()
        return path
    }
}

private struct WaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.width * 0.45, y: rect.height * 0.18),
            control2: CGPoint(x: rect.width * 0.05, y: rect.height * 0.78)
        )
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control1: CGPoint(x: rect.width * 0.86, y: rect.height * 0.60),
            control2: CGPoint(x: rect.width * 0.65, y: rect.height * 0.18)
        )
        path.closeSubpath()
        return path
    }
}
