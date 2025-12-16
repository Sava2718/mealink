import SwiftUI

struct ManualInputView: View {
    @State private var name = ""
    @State private var quantity = ""
    @State private var unit = ""
    @State private var location = "冷蔵"
    @State private var expires = ""

    var body: some View {
        Form {
            Section(header: Text("食材情報")) {
                TextField("食材名", text: $name)
                TextField("数量", text: $quantity)
                    .keyboardType(.decimalPad)
                TextField("単位 (例: 個, g)", text: $unit)
                Picker("保管場所", selection: $location) {
                    ForEach(["冷蔵", "冷凍", "常温"], id: \.self) { Text($0) }
                }
                TextField("賞味期限 (任意 YYYY-MM-DD)", text: $expires)
            }

            Section {
                Button("この内容で登録する") {
                    // TODO: register action (後でSupabase連携)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("手入力で追加")
    }
}
