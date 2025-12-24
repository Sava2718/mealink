import SwiftUI

struct TodayMenuView: View {
    let dataProvider: any DataProvider

    @State private var recipes: [DBRecipeSummaryRow] = []
    @State private var selectedCuisine: String = "すべて"
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("今日の献立")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(Color(hex: "#3E4B50"))
                        .padding(.top, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(availableCuisines, id: \.self) { cat in
                                CategoryChip(label: cat, selected: cat == selectedCuisine)
                                    .onTapGesture { selectedCuisine = cat }
                            }
                        }
                    }

                    if isLoading {
                        ProgressView().frame(maxWidth: .infinity, alignment: .center)
                    } else if let message = errorMessage {
                        ErrorCard(message: message, retry: load)
                    } else {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeCard(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button(action: {}) {
                        Text("これにする")
                            .font(.system(size: 18, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(.white)
                            .background(Color(hex: "#F28245"))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(Color(hex: "#FBE4CC"))
            .task { await load() }
            .navigationDestination(for: DBRecipeSummaryRow.self) { recipe in
                RecipeDetailView(recipeId: recipe.recipe_id)
            }
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            recipes = try await dataProvider.fetchRecipeSummary()
            print("[TodayMenu] fetched summaries count:", recipes.count)
            if !availableCuisines.contains(selectedCuisine) { selectedCuisine = "すべて" }
            isLoading = false
        } catch {
            errorMessage = "レシピの取得に失敗しました。\n\(error.localizedDescription)"
            isLoading = false
        }
    }

    private var availableCuisines: [String] {
        let cuisines = recipes.compactMap { $0.cuisine?.isEmpty == false ? $0.cuisine : nil }
        let unique = Array(Set(cuisines)).sorted()
        return ["すべて"] + unique
    }

    private var filteredRecipes: [DBRecipeSummaryRow] {
        guard selectedCuisine != "すべて" else { return recipes }
        return recipes.filter { $0.cuisine == selectedCuisine }
    }
}

struct RecipeCard: View {
    let recipe: DBRecipeSummaryRow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let urlString = recipe.photo_url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure(_):
                        placeholder
                    case .empty:
                        ZStack { placeholder; ProgressView() }
                    @unknown default:
                        placeholder
                    }
                }
                .frame(height: 200)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                placeholder
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.recipe_name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "#3E4B50"))

                HStack(spacing: 8) {
                    if let min = recipe.cook_time { TagView(text: "約\(min)分") }
                    if let s = recipe.servings { TagView(text: "\(s)人前") }
                    TagView(text: recipe.can_cook ? "作れる" : "不足あり", color: recipe.can_cook ? Color(hex: "#68C29E") : Color(hex: "#E86F71"))
                    TagView(text: "不足 \(recipe.shortage_items_count)")
                }
            }
            .padding(16)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.3)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing))
            .overlay(Image(systemName: "fork.knife.circle.fill").font(.system(size: 64)).foregroundStyle(.white))
    }
}

struct ErrorCard: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundStyle(Color(hex: "#E86F71"))
                Text(message)
                    .font(.system(size: 14, weight: .bold))
            }
            Button(action: { Task { await retry() } }) {
                Label("再読込", systemImage: "arrow.clockwise")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: "#F3A16E").opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}
