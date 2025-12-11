import SwiftUI

struct MyPageView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle().fill(Color(hex: "#BCEFD6")).frame(width: 48, height: 48)
                            .overlay(Image(systemName: "person.fill").foregroundStyle(.white))
                        VStack(alignment: .leading) {
                            Text("ユーザー名").font(.headline)
                            Text("目標: 健康維持 / 週5自炊").font(.subheadline).foregroundStyle(.gray)
                        }
                    }
                }
                Section {
                    Label("通知設定", systemImage: "bell")
                    Label("プライバシー設定", systemImage: "lock")
                    Label("ログアウト", systemImage: "rectangle.portrait.and.arrow.forward")
                        .foregroundStyle(.red)
                }
            }
            .navigationTitle("マイページ")
        }
    }
}
