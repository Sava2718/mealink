import SwiftUI

struct RecordInputView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("記録（レシート・食材）")
                    .font(.system(size: 24, weight: .heavy))
                    .foregroundStyle(Color(hex: "#3E4B50"))
                    .padding(.top, 8)

                ActionCard(
                    color: Color(hex: "#56ACC7"),
                    icon: "camera",
                    title: "レシートを撮影",
                    description: "レシート画像から在庫を更新します",
                    actionLabel: "撮影する",
                    action: {}
                )
                ActionCard(
                    color: Color(hex: "#68C29E"),
                    icon: "plus.rectangle.on.rectangle",
                    title: "食材を手入力",
                    description: "商品名と数量を入力して在庫に追加",
                    actionLabel: "追加する",
                    action: {}
                )
                ActionCard(
                    color: Color(hex: "#F3A16E"),
                    icon: "icloud.and.arrow.up",
                    title: "ネットスーパー履歴を取り込み",
                    description: "CSVやスクショをアップロード（デモ）",
                    actionLabel: "アップロード",
                    action: {}
                )
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGray6))
    }
}
