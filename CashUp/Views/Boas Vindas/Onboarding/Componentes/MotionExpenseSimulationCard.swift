import SwiftUI

struct MotionExpenseSimulationCard: View {
    @State private var valorExibido: String = "R$ 0,00"
    @State private var categoriaSelecionada: Bool = false
    @State private var cursorVisivel: Bool = true

    var body: some View {
        VStack(spacing: 20) {
            headerBar

            tipoSegmentedControl

            valorSection

            categoriaLinha
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 22/255, green: 28/255, blue: 36/255))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .task {
            cursorVisivel = true
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(700))
                guard !Task.isCancelled else { break }
                withAnimation(.easeOut(duration: 0.15)) {
                    valorExibido = "R$ 4"
                }

                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { break }
                withAnimation(.easeOut(duration: 0.15)) {
                    valorExibido = "R$ 40"
                }

                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { break }
                withAnimation(.easeOut(duration: 0.15)) {
                    valorExibido = "R$ 40,00"
                }

                try? await Task.sleep(for: .milliseconds(600))
                guard !Task.isCancelled else { break }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                    categoriaSelecionada = true
                }

                try? await Task.sleep(for: .milliseconds(2800))
                guard !Task.isCancelled else { break }
                withAnimation(.easeInOut(duration: 0.25)) {
                    valorExibido = "R$ 0,00"
                    categoriaSelecionada = false
                }
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Text("Cancelar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(red: 245/255, green: 90/255, blue: 90/255))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                )

            Spacer()

            Text("Registrar Despesa")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Text("Adicionar")
                .font(.caption.weight(.semibold))
                .foregroundStyle(categoriaSelecionada ? .white : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(categoriaSelecionada ? Color.blue : Color.white.opacity(0.08))
                )
                .animation(.easeInOut(duration: 0.2), value: categoriaSelecionada)
        }
    }

    private var tipoSegmentedControl: some View {
        HStack(spacing: 0) {
            Text("Despesa")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.18))
                )

            Text("Receita")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color.white.opacity(0.45))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }

    private var valorSection: some View {
        HStack(alignment: .center, spacing: 3) {
            Spacer()

            Text(valorExibido)
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Rectangle()
                .fill(Color.blue)
                .frame(width: 2.5, height: 32)
                .opacity(cursorVisivel ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: cursorVisivel)

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private var categoriaLinha: some View {
        HStack(spacing: 12) {
            if categoriaSelecionada {
                ZStack {
                    Circle()
                        .fill(Color(red: 0/255, green: 199/255, blue: 190/255))
                        .frame(width: 34, height: 34)

                    Image(systemName: "carrot.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .transition(.scale.combined(with: .opacity))

                Text("Comida")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .transition(.opacity)
            } else {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .transition(.scale.combined(with: .opacity))

                Text("Selecionar categoria")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                    .transition(.opacity)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: categoriaSelecionada)
    }
}
