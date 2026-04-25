import PhotosUI
import SwiftUI
import UIKit

struct StudioView: View {
    @State private var selectedTool = "Pan"
    @State private var motionPrompt = ""
    @State private var isGenerating = false
    @State private var successMessage: String?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var imageSelectionMessage: String?
    @State private var imageScale: CGFloat = 1
    @State private var imageOffset: CGSize = .zero
    @State private var activeImageAdjustment: ImageAdjustmentSession?
    @State private var annotations: [StudioAnnotation] = []
    @State private var activeStroke: AnnotationStroke?
    @State private var activeCircle: AnnotationCircle?
    @State private var pendingTextPosition: CGPoint?
    @State private var isPresentingTextAnnotation = false

    var onGeneratedClip: (GeneratedClip) -> Void = { _ in }

    private let tools = [
        ("Pan", "wand.and.stars"),
        ("Draw", "pencil.tip"),
        ("Circle", "circle"),
        ("Text", "textformat")
    ]

    var body: some View {
        VStack(spacing: 0) {
            studioHeader

            ScrollView {
                VStack(spacing: 20) {
                    canvas

                    toolPicker

                    TextField("Describe the motion...", text: $motionPrompt)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(PannotateTheme.Colors.primaryText)
                        .padding(.horizontal, 16)
                        .frame(height: 58)
                        .background(PannotateTheme.Colors.cardMuted)
                        .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
                        )

                    generateButton

                    if let successMessage {
                        Label(successMessage, systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PannotateTheme.Colors.success)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if let imageSelectionMessage {
                        Label(imageSelectionMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(PannotateTheme.Metrics.pagePadding)
                .padding(.top, 50)
                .padding(.bottom, PannotateTheme.Metrics.tabBarContentInset)
            }
        }
        .pannotatePage()
        .onChange(of: selectedPhotoItem) { _, newItem in
            loadSelectedPhoto(newItem)
        }
        .fullScreenCover(item: $activeImageAdjustment) { session in
            ImageAdjustmentView(session: session) { image, scale, offset in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    selectedImage = image
                    imageScale = scale
                    imageOffset = offset
                    if session.clearsAnnotationsOnConfirm {
                        clearAnnotations()
                    }
                    successMessage = nil
                }

                activeImageAdjustment = nil
            } onCancel: {
                activeImageAdjustment = nil
            }
        }
        .sheet(isPresented: $isPresentingTextAnnotation) {
            ManagementRenameSheet(title: "Add Text", placeholder: "Annotation text", initialName: "") { text in
                addTextAnnotation(text)
            }
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var generateButton: some View {
        Button {
            generateMockVideo()
        } label: {
            HStack(spacing: 10) {
                if isGenerating {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "sparkles")
                }

                Text(isGenerating ? "Generating..." : "Generate Video")
            }
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(generateButtonColor)
            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
            .shadow(color: hasRequiredInputs ? PannotateTheme.Colors.accent.opacity(0.32) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .disabled(!hasRequiredInputs || isGenerating)
        .animation(.easeInOut(duration: 0.2), value: isGenerating)
        .animation(.easeInOut(duration: 0.2), value: hasRequiredInputs)
    }

    private var hasRequiredInputs: Bool {
        selectedImage != nil && !motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var generateButtonColor: Color {
        if isGenerating {
            return PannotateTheme.Colors.accent.opacity(0.72)
        }

        return hasRequiredInputs ? PannotateTheme.Colors.accent : PannotateTheme.Colors.tertiaryText.opacity(0.52)
    }

    private func generateMockVideo() {
        guard let selectedImage else { return }

        successMessage = nil
        isGenerating = true

        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)

            await MainActor.run {
                let clip = GeneratedClip(
                    title: generatedClipTitle,
                    duration: "4s",
                    createdAt: "Just now",
                    status: .done,
                    thumbnail: .city,
                    image: selectedImage
                )

                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isGenerating = false
                    successMessage = "Mock clip generated"
                }

                onGeneratedClip(clip)
            }
        }
    }

    private var generatedClipTitle: String {
        let prompt = motionPrompt.trimmingCharacters(in: .whitespacesAndNewlines)

        if prompt.count <= 32 {
            return prompt.isEmpty ? "Studio Mock Clip" : prompt
        }

        return "\(prompt.prefix(32))..."
    }

    private func loadSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }

        imageSelectionMessage = nil

        Task {
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    await MainActor.run {
                        imageSelectionMessage = "Could not load that photo"
                    }
                    return
                }

                await MainActor.run {
                    activeImageAdjustment = ImageAdjustmentSession(image: image)
                }
            } catch {
                await MainActor.run {
                    imageSelectionMessage = "Photo selection was cancelled or unavailable"
                }
            }
        }
    }

    private var studioHeader: some View {
        HStack {
            Text("Studio")
                .font(.title2.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.primaryText)

            Spacer()

            Image(systemName: "ellipsis")
                .font(.title2.weight(.bold))
                .foregroundStyle(PannotateTheme.Colors.secondaryText)
        }
        .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
        .frame(height: 62)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(PannotateTheme.Colors.border)
                .frame(height: 1)
        }
    }

    private var canvas: some View {
        ZStack {
            if let selectedImage {
                annotatedImageCanvas(selectedImage)

                HStack(spacing: 10) {
                    Button {
                        activeImageAdjustment = ImageAdjustmentSession(
                            image: selectedImage,
                            initialScale: imageScale,
                            initialOffset: imageOffset,
                            clearsAnnotationsOnConfirm: false
                        )
                    } label: {
                        canvasOverlayLabel("Adjust", systemImage: "crop")
                    }
                    .buttonStyle(.plain)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        canvasOverlayLabel("Change", systemImage: "photo")
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(14)
            } else {
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 42, weight: .semibold))
                            .foregroundStyle(PannotateTheme.Colors.accent)

                        Text("Select an Image")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(PannotateTheme.Colors.primaryText)

                        Text("Choose a photo to start guiding motion")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 224)
                    .background(PannotateTheme.cardGradient)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 224)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func annotatedImageCanvas(_ image: UIImage) -> some View {
        GeometryReader { geometry in
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .clipped()

                annotationOverlay
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(false)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .gesture(annotationGesture(in: geometry.size), including: selectedTool == "Pan" ? .subviews : .all)
        }
    }

    private func canvasOverlayLabel(_ title: String, systemImage: String) -> some View {
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial.opacity(0.72))
            .clipShape(Capsule())
    }

    private var toolPicker: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(tools, id: \.0) { tool in
                    let isSelected = selectedTool == tool.0

                    Button {
                        selectedTool = tool.0
                    } label: {
                        Label(tool.0, systemImage: tool.1)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(isSelected ? PannotateTheme.Colors.accent : PannotateTheme.Colors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isSelected ? PannotateTheme.Colors.accentSoft.opacity(0.72) : PannotateTheme.Colors.cardMuted)
                            .clipShape(RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: PannotateTheme.Metrics.controlRadius, style: .continuous)
                                    .stroke(isSelected ? PannotateTheme.Colors.accent.opacity(0.8) : .clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            annotationControls
        }
    }

    private var annotationControls: some View {
        HStack(spacing: 10) {
            Button {
                undoLastAnnotation()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(canUndoAnnotations ? PannotateTheme.Colors.secondaryText : PannotateTheme.Colors.tertiaryText.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canUndoAnnotations)

            Button(role: .destructive) {
                withAnimation(.easeInOut(duration: 0.18)) {
                    clearAnnotations()
                }
            } label: {
                Label("Clear", systemImage: "eraser")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(canUndoAnnotations ? .red : PannotateTheme.Colors.tertiaryText.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(PannotateTheme.Colors.cardMuted)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canUndoAnnotations)
        }
    }

    private var canUndoAnnotations: Bool {
        annotations.isEmpty == false || activeStroke != nil || activeCircle != nil
    }

    private var annotationOverlay: some View {
        ZStack {
            ForEach(annotations) { annotation in
                annotationView(annotation)
            }

            if let activeStroke {
                strokeView(activeStroke)
            }

            if let activeCircle {
                circleView(activeCircle)
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func annotationView(_ annotation: StudioAnnotation) -> some View {
        switch annotation {
        case .stroke(let stroke):
            strokeView(stroke)
        case .circle(let circle):
            circleView(circle)
        case .text(let text):
            textView(text)
        }
    }

    private func strokeView(_ stroke: AnnotationStroke) -> some View {
        Path { path in
            guard let firstPoint = stroke.points.first else { return }

            path.move(to: firstPoint)

            for point in stroke.points.dropFirst() {
                path.addLine(to: point)
            }
        }
        .stroke(PannotateTheme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
    }

    private func circleView(_ circle: AnnotationCircle) -> some View {
        Ellipse()
            .stroke(PannotateTheme.Colors.accent, lineWidth: 4)
            .frame(width: circle.rect.width, height: circle.rect.height)
            .position(x: circle.rect.midX, y: circle.rect.midY)
    }

    private func textView(_ text: AnnotationText) -> some View {
        Text(text.text)
            .font(.headline.weight(.heavy))
            .foregroundStyle(PannotateTheme.Colors.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(PannotateTheme.Colors.accent.opacity(0.86))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.62), lineWidth: 1)
            )
            .position(text.position)
    }

    private func annotationGesture(in canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: selectedTool == "Text" ? 0 : 2)
            .onChanged { value in
                switch selectedTool {
                case "Draw":
                    updateActiveStroke(with: clampedPoint(value.location, in: canvasSize))
                case "Circle":
                    updateActiveCircle(start: clampedPoint(value.startLocation, in: canvasSize), current: clampedPoint(value.location, in: canvasSize))
                default:
                    break
                }
            }
            .onEnded { value in
                switch selectedTool {
                case "Draw":
                    commitActiveStroke()
                case "Circle":
                    commitActiveCircle()
                case "Text":
                    pendingTextPosition = clampedPoint(value.location, in: canvasSize)
                    isPresentingTextAnnotation = true
                default:
                    break
                }
            }
    }

    private func updateActiveStroke(with point: CGPoint) {
        if activeStroke == nil {
            activeStroke = AnnotationStroke(points: [point])
        } else {
            activeStroke?.points.append(point)
        }
    }

    private func commitActiveStroke() {
        guard let activeStroke, activeStroke.points.count > 1 else {
            activeStroke = nil
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            annotations.append(.stroke(activeStroke))
        }
        self.activeStroke = nil
    }

    private func updateActiveCircle(start: CGPoint, current: CGPoint) {
        activeCircle = AnnotationCircle(rect: CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        ))
    }

    private func commitActiveCircle() {
        guard let activeCircle, activeCircle.rect.width > 8, activeCircle.rect.height > 8 else {
            activeCircle = nil
            return
        }

        withAnimation(.easeInOut(duration: 0.12)) {
            annotations.append(.circle(activeCircle))
        }
        self.activeCircle = nil
    }

    private func addTextAnnotation(_ text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.isEmpty == false, let pendingTextPosition else { return }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            annotations.append(.text(AnnotationText(text: trimmedText, position: pendingTextPosition)))
        }

        self.pendingTextPosition = nil
    }

    private func undoLastAnnotation() {
        withAnimation(.easeInOut(duration: 0.18)) {
            if activeStroke != nil {
                activeStroke = nil
            } else if activeCircle != nil {
                activeCircle = nil
            } else if annotations.isEmpty == false {
                annotations.removeLast()
            }
        }
    }

    private func clearAnnotations() {
        annotations.removeAll()
        activeStroke = nil
        activeCircle = nil
        pendingTextPosition = nil
    }

    private func clampedPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), size.width),
            y: min(max(point.y, 0), size.height)
        )
    }
}

private struct ImageAdjustmentSession: Identifiable {
    let id = UUID()
    let image: UIImage
    var initialScale: CGFloat = 1
    var initialOffset: CGSize = .zero
    var clearsAnnotationsOnConfirm = true
}

private struct AnnotationStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
}

private struct AnnotationCircle: Identifiable {
    let id = UUID()
    var rect: CGRect
}

private struct AnnotationText: Identifiable {
    let id = UUID()
    var text: String
    var position: CGPoint
}

private enum StudioAnnotation: Identifiable {
    case stroke(AnnotationStroke)
    case circle(AnnotationCircle)
    case text(AnnotationText)

    var id: UUID {
        switch self {
        case .stroke(let stroke):
            stroke.id
        case .circle(let circle):
            circle.id
        case .text(let text):
            text.id
        }
    }
}

private struct ImageAdjustmentView: View {
    @Environment(\.dismiss) private var dismiss
    let session: ImageAdjustmentSession
    let onConfirm: (UIImage, CGFloat, CGSize) -> Void
    let onCancel: () -> Void

    @State private var imageScale: CGFloat
    @State private var lastImageScale: CGFloat
    @State private var imageOffset: CGSize
    @State private var lastImageOffset: CGSize

    init(
        session: ImageAdjustmentSession,
        onConfirm: @escaping (UIImage, CGFloat, CGSize) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.session = session
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        _imageScale = State(initialValue: session.initialScale)
        _lastImageScale = State(initialValue: session.initialScale)
        _imageOffset = State(initialValue: session.initialOffset)
        _lastImageOffset = State(initialValue: session.initialOffset)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Text("Frame the image before annotating. This is a local prototype adjustment only.")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(PannotateTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PannotateTheme.Metrics.pagePadding)

                adjustmentCanvas
                    .padding(.horizontal, PannotateTheme.Metrics.pagePadding)

                Label("Drag to reposition. Pinch to zoom.", systemImage: "hand.draw")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(PannotateTheme.Colors.tertiaryText)

                Spacer()

                PrimaryActionButton(title: "Use This Framing", systemImage: "checkmark") {
                    onConfirm(session.image, imageScale, imageOffset)
                    dismiss()
                }
                .padding(.horizontal, PannotateTheme.Metrics.pagePadding)
                .padding(.bottom, 18)
            }
            .padding(.top, 20)
            .background(PannotateTheme.Colors.background.ignoresSafeArea())
            .navigationTitle("Adjust Image")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                            imageScale = 1
                            lastImageScale = 1
                            imageOffset = .zero
                            lastImageOffset = .zero
                        }
                    }
                }
            }
        }
    }

    private var adjustmentCanvas: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black

                Image(uiImage: session.image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(imageAdjustmentGesture(in: geometry.size))

                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.24), lineWidth: 1)
            }
        }
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(PannotateTheme.Colors.border, lineWidth: 1)
        )
    }

    private func imageAdjustmentGesture(in canvasSize: CGSize) -> some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let proposedOffset = CGSize(
                        width: lastImageOffset.width + value.translation.width,
                        height: lastImageOffset.height + value.translation.height
                    )

                    imageOffset = clampedOffset(proposedOffset, canvasSize: canvasSize, scale: imageScale)
                }
                .onEnded { _ in
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                    lastImageOffset = imageOffset
                },
            MagnificationGesture()
                .onChanged { value in
                    imageScale = clampedScale(lastImageScale * value)
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                }
                .onEnded { _ in
                    imageScale = clampedScale(imageScale)
                    imageOffset = clampedOffset(imageOffset, canvasSize: canvasSize, scale: imageScale)
                    lastImageScale = imageScale
                    lastImageOffset = imageOffset
                }
        )
    }

    private func clampedScale(_ scale: CGFloat) -> CGFloat {
        min(max(scale, 1), 4)
    }

    private func clampedOffset(_ offset: CGSize, canvasSize: CGSize, scale: CGFloat) -> CGSize {
        let maxX = canvasSize.width * max(scale - 1, 0) / 2
        let maxY = canvasSize.height * max(scale - 1, 0) / 2

        return CGSize(
            width: min(max(offset.width, -maxX), maxX),
            height: min(max(offset.height, -maxY), maxY)
        )
    }
}

#Preview {
    StudioView()
}
