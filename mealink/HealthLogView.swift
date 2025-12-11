import SwiftUI

struct HealthLogView: View {
    let meals: [MealLog] = [
        .init(time: "朝", menu: "トースト", icon: "sun.max"),
        .init(time: "昼", menu: "サラダチキン", icon: "cup.and.saucer"),
        .init(time: "夜", menu: "未入力", icon: "moon.stars"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("記録と健康スコア")
                    .font(.system(size: 26, weight: .heavy))
                    .foregroundStyle(Color(hex: "#3E4B50"))
                    .padding(.top, 8)

                VStack(spacing: 16) {
                    ScoreRing(score: 78)
                    Text("栄養バランス")
                        .font(.system(size: 16, weight: .bold))
                    RadarChart(values: [0.65, 0.5, 0.7, 0.45, 0.55], labels: ["食質", "酵素", "おはんや物", "脂質", "たんぱく質"])
                        .frame(height: 200)
                    GuidanceBubble(text: "あと野菜を一品食べましょう！")
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)

                Text("食事ログ")
                    .font(.system(size: 18, weight: .bold))
                ForEach(meals) { meal in
                    MealRow(meal: meal)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(Color(hex: "#BCEFD6").opacity(0.45))
    }
}
