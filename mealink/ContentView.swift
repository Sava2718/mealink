//
//  ContentView.swift
//  mealink
//

import SwiftUI

struct ContentView: View {
    private let dataProvider: any DataProvider = SupabaseProviderFactory.make() ?? MockDataProvider()

    var body: some View {
        TabView {
            HomeView(dataProvider: dataProvider)
                .tabItem { Label("ホーム", systemImage: "house") }

            InventoryView(dataProvider: dataProvider)
                .tabItem { Label("在庫", systemImage: "cabinet") }

            CaptureView()
                .tabItem { Label("記録", systemImage: "plus.circle") }

            RecipeRootView(dataProvider: dataProvider)
                .tabItem { Label("検索", systemImage: "magnifyingglass") }

            MyPageView()
                .tabItem { Label("マイページ", systemImage: "person.circle") }
        }
        .tint(Color(hex: "#F3A16E"))
        .preferredColorScheme(.light)
        .onAppear {
#if DEBUG
            print("[Supabase] moduleAvailable=\(SupabaseClients.shared.moduleAvailable), isConfigured=\(SupabaseClients.shared.isConfigured)")
#endif
        }
    }
}

#Preview {
    ContentView()
}

// MARK: - New tab roots

private struct HomeView: View {
    let dataProvider: any DataProvider
    private let planRepo = DailyPlanRepository()

    @State private var plan: DailyPlan?
    @State private var plannedRecipe: DBRecipeSummaryRow?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSearch = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("ホーム")
                        .font(.title).bold()
                        .padding(.top, 8)

                    if isLoading {
                        HStack { Spacer(); ProgressView(); Spacer() }
                    } else if let message = errorMessage {
                        Text(message)
                            .foregroundColor(.red)
                            .font(.subheadline)
                    } else {
                        Text("今日の夜ごはん")
                            .font(.headline)

                        if let recipe = plannedRecipe {
                            HomeRecipeCard(recipe: recipe)
                            HStack {
                                Button("今日作る") {
                                    // TODO: レシピ詳細への遷移などは後続で実装
                                }
                                .buttonStyle(.borderedProminent)

                                Button("変更") { showSearch = true }
                                    .buttonStyle(.bordered)
                            }
                        } else {
                            Text("今ある食材で作れる料理を探します。")
                                .foregroundColor(.gray)
                                .font(.subheadline)
                            Button("今あるもので探す") { showSearch = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
            }
            .task { await loadPlanAndRecipe() }
            .navigationDestination(isPresented: $showSearch) {
                SearchView(
                    dataProvider: dataProvider,
                    planRepo: planRepo
                ) {
                    showSearch = false
                    Task { await loadPlanAndRecipe() }
                }
            }
        }
    }

    @MainActor
    private func loadPlanAndRecipe() async {
        isLoading = true
        errorMessage = nil
        do {
            guard let repo = planRepo else {
                errorMessage = "Supabaseが利用できません"
                isLoading = false
                return
            }
            let fetchedPlan = try await repo.fetchTodayDinnerPlan()
            plan = fetchedPlan
            plannedRecipe = nil

            if let recipeId = fetchedPlan?.planned_recipe_id {
                // シンプルに一覧を取得して該当を探す（MVP優先）
                let list = try await dataProvider.fetchRecipeSummary()
                plannedRecipe = list.first { $0.recipe_id == recipeId }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

private struct CaptureView: View {
    // 既存の手入力画面などへの入口
    var body: some View {
        NavigationStack {
            RecordInputView()
                .navigationTitle("記録")
        }
    }
}

private struct RecipeRootView: View {
    let dataProvider: any DataProvider
    var body: some View {
        TodayMenuView(dataProvider: dataProvider)
    }
}

// MARK: - Home recipe card

private struct HomeRecipeCard: View {
    let recipe: DBRecipeSummaryRow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let urlString = recipe.photo_url, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        ZStack { placeholder; ProgressView() }
                    @unknown default:
                        placeholder
                    }
                }
                .frame(height: 180)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                placeholder
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(recipe.recipe_name)
                    .font(.headline)
                    .foregroundStyle(Color(hex: "#3E4B50"))

                HStack(spacing: 8) {
                    if let min = recipe.cook_time { TagView(text: "約\(min)分") }
                    if let s = recipe.servings { TagView(text: "\(s)人前") }
                    TagView(text: recipe.can_cook ? "作れる" : "不足あり", color: recipe.can_cook ? Color(hex: "#68C29E") : Color(hex: "#E86F71"))
                    TagView(text: "不足 \(recipe.shortage_items_count)")
                }
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var placeholder: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color.orange.opacity(0.6), Color.orange.opacity(0.3)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing))
            .overlay(Image(systemName: "fork.knife.circle.fill").font(.system(size: 48)).foregroundStyle(.white))
    }
}

// MARK: - Search View for daily plan selection

private struct SearchView: View {
    let dataProvider: any DataProvider
    let planRepo: DailyPlanRepository?
    let onDecide: () -> Void

    @State private var recipes: [DBRecipeSummaryRow] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let message = errorMessage {
                Text(message).foregroundColor(.red)
            } else {
                ForEach(recipes) { recipe in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(recipe.recipe_name).font(.headline)
                        HStack(spacing: 8) {
                            if let m = recipe.cook_time { Text("約\(m)分").font(.caption) }
                            if let s = recipe.servings { Text("\(s)人前").font(.caption) }
                        }
                        Button {
                            Task {
                                do {
                                    guard let repo = planRepo else {
                                        errorMessage = "Supabaseが利用できません"; return
                                    }
                                    try await repo.upsertTodayDinner(planRecipeId: recipe.recipe_id)
                                    onDecide()
                                } catch {
                                    errorMessage = error.localizedDescription
                                }
                            }
                        } label: {
                            Text("今日はこれにする")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("条件で探す")
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            recipes = try await dataProvider.fetchRecipeSummary()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
