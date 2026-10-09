import SwiftUI

struct ErrorAlertModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content.alert("Erro", isPresented: Binding(
            get: { message != nil },
            set: { if !$0 { message = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message ?? "")
        }
    }
}

extension View {
    func errorAlert(_ message: Binding<String?>) -> some View {
        modifier(ErrorAlertModifier(message: message))
    }
}
