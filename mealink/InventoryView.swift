import SwiftUI

struct InventoryView: View {
    let dataProvider: any DataProvider

    @State private var items: [InventoryItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color(.systemGray6).ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("冷蔵庫の中身")
                        .font(.system(size: 28, weight: .heavy))
                        .foregroundStyle(.black)
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
                        ForEach(groupedByLocation.keys.sorted(), id: \.self) { key in
                            if let list = groupedByLocation[key] {
                                Text(key)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.black)
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
                        .background(Color.blue.opacity(0.85))
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

    private var groupedByLocation: [String: [InventoryItem]] {
        Dictionary(grouping: items, by: { item in
            let loc = item.location?.isEmpty == false ? item.location! : "未設定"
            return loc
        })
    }
}
