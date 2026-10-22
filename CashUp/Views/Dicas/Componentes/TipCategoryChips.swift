import SwiftUI

struct TipCategoryChips: View {
    @Binding var selectedCategory: TipCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(title: "Todas", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }

                ForEach(TipCategory.allCases, id: \.self) { category in
                    chipButton(
                        title: category.titulo,
                        icon: category.iconName,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private func chipButton(
        title: String,
        icon: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundColor(isSelected ? .black : .white)
            .background(isSelected ? Color.white : Color(red: 0.16, green: 0.16, blue: 0.18))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
