import SwiftUI

/// 詳細画面：rpc_recipe_requirements で必要食材を表示
struct RecipeDetailView: View, Hashable {
    let recipeId: UUID
    private let dataProvider: any DataProvider = SupabaseProviderFactory.make() ?? MockDataProvider()

    @State private var rows: [DBRecipeRequirementRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                Text("recipe_id: \(recipeId.uuidString)")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
            if isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let message = errorMessage {
                Text(message).foregroundColor(.red)
            } else {
                ForEach(rows) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.ingredientName)
                            .font(.headline)
                        HStack {
                            let req = row.requiredAmount ?? 0
                            Text("必要: \(req) \(row.requiredUnit)")
                            Spacer()
                            let stock = row.inStockAmount ?? 0
                            Text("在庫: \(stock, specifier: "%.1f") \(row.requiredUnit)")
                                .foregroundColor(.gray)
                        }
                        if let shortage = row.shortageAmount, shortage > 0 {
                            Text("不足: \(shortage, specifier: "%.1f") \(row.requiredUnit)")
                                .font(.caption)
                                .foregroundColor(.red)
                        } else {
                            Text("足りてる")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .navigationTitle("レシピ詳細")
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            rows = try await dataProvider.fetchRecipeRequirements(recipeId: recipeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    static func == (lhs: RecipeDetailView, rhs: RecipeDetailView) -> Bool {
        lhs.recipeId == rhs.recipeId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(recipeId)
    }
}
