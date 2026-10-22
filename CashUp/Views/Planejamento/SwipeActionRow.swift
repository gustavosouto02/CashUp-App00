import SwiftUI

struct SwipeActionRow<Content: View>: View {
    var isEnabled: Bool = true
    @ViewBuilder let content: Content
    let onDelete: () -> Void

    @State private var offset: CGFloat = 0
    @State private var isRevealed: Bool = false
    private let buttonWidth: CGFloat = 72

    init(
        isEnabled: Bool = true,
        @ViewBuilder content: () -> Content,
        onDelete: @escaping () -> Void
    ) {
        self.isEnabled = isEnabled
        self.content = content()
        self.onDelete = onDelete
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            // Botão de excluir com ícone de lixeira
            HStack(spacing: 0) {
                Spacer()
                Button(role: .destructive) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        offset = 0
                        isRevealed = false
                    }
                    onDelete()
                } label: {
                    ZStack {
                        Color.red
                        Image(systemName: "trash.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: buttonWidth)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Excluir")
            }

            // Conteúdo principal que desliza
            content
                .background(Color(.secondarySystemGroupedBackground))
                .offset(x: offset)
                .onTapGesture {
                    if isRevealed {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            offset = 0
                            isRevealed = false
                        }
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 15, coordinateSpace: .local)
                        .onChanged { gesture in
                            guard isEnabled else { return }
                            guard abs(gesture.translation.width) > abs(gesture.translation.height) else { return }

                            // Permite apenas arrastar para a esquerda
                            if gesture.translation.width < 0 {
                                let base = isRevealed ? -buttonWidth : 0
                                let newOffset = base + gesture.translation.width
                                offset = max(newOffset, -buttonWidth * 1.4)
                            } else if isRevealed {
                                let newOffset = -buttonWidth + gesture.translation.width
                                offset = min(newOffset, 0)
                            }
                        }
                        .onEnded { gesture in
                            guard isEnabled else { return }
                            guard abs(gesture.translation.width) > abs(gesture.translation.height) else {
                                if isRevealed {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        offset = -buttonWidth
                                    }
                                }
                                return
                            }

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if gesture.translation.width < -35 || gesture.predictedEndTranslation.width < -50 {
                                    offset = -buttonWidth
                                    isRevealed = true
                                } else {
                                    offset = 0
                                    isRevealed = false
                                }
                            }
                        }
                )
        }
        .clipped()
        .onChange(of: isEnabled) { _, enabled in
            if !enabled && (isRevealed || offset != 0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = 0
                    isRevealed = false
                }
            }
        }
    }
}
