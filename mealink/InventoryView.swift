import SwiftUI

struct InventoryView: View {
    let dataProvider: any DataProvider

    @State private var items: [InventoryItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(hex: "#DFF3F7").ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("冷蔵庫の中身")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(Color(hex: "#3E4B50"))
                        .padding(.top, 8)

                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity, alignment: .center)
                    } else if let message = errorMessage {
                        ErrorCard(message: message, retry: load)
                    } else if items.isEmpty {
                        Text("在庫がありません")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(groupedByCategory.keys.sorted(), id: \.self) { key in
                            if let list = groupedByCategory[key] {
                                Text(key)
                                    .font(.system(size: 18, weight: .bold))
                                ForEach(list) { item in
                                    InventoryCardView(item: item)
                                }
                                .padding(.bottom, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 80)
            }
            .overlay(alignment: .bottomTrailing) {
                Button(action: { Task { await load() } }) {
                    Label("再読込", systemImage: "arrow.clockwise")
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(Color(hex: "#56ACC7"))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 6)
                }
                .padding(.trailing, 18)
                .padding(.bottom, 24)
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            items = try await dataProvider.fetchInventory()
            isLoading = false
        } catch {
            errorMessage = "在庫の取得に失敗しました。\n\(error.localizedDescription)"
            isLoading = false
        }
    }

    private var groupedByCategory: [String: [InventoryItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
}
