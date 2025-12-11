//
//  ContentView.swift
//  mealink
//

import SwiftUI

struct ContentView: View {
    private let dataProvider: any DataProvider = MockDataProvider()

    var body: some View {
        TabView {
            TodayMenuView(dataProvider: dataProvider)
                .tabItem { Label("今日の献立", systemImage: "fork.knife") }

            InventoryView(dataProvider: dataProvider)
                .tabItem { Label("在庫", systemImage: "cabinet") }

            RecordInputView()
                .tabItem { Label("記録(入力)", systemImage: "doc.text.viewfinder") }

            HealthLogView()
                .tabItem { Label("記録(ログ)", systemImage: "chart.line.uptrend.xyaxis") }

            MyPageView()
                .tabItem { Label("マイページ", systemImage: "person.circle") }
        }
        .tint(Color(hex: "#F3A16E"))
    }
}

#Preview {
    ContentView()
}
