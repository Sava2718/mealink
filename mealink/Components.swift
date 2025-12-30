import SwiftUI

// MARK: - Shared UI

struct CategoryChip: View {
    let label: String
    let selected: Bool

    var body: some View {
        Text(label)
            .font(.system(size: 14, weight: .semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Color.white : Color.white.opacity(0.7))
            .foregroundStyle(selected ? Color.black : Color.black.opacity(0.7))
            .clipShape(Capsule())
    }
}

struct TagView: View {
    let text: String
    var color: Color? = nil

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((color ?? Color.white).opacity(0.8))
            .foregroundStyle(color ?? Color.black)
            .clipShape(Capsule())
    }
}

struct ActionCard: View {
    let color: Color
    let icon: String
    let title: String
    let description: String
    let actionLabel: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .frame(width: 48, height: 48)
                .overlay(Image(systemName: icon).foregroundStyle(color))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 16, weight: .bold))
                Text(description).font(.system(size: 14)).foregroundStyle(.gray)
            }
            Spacer()
            Button(action: action) {
                Text(actionLabel)
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.12))
                    .foregroundStyle(color)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }
}

struct InventoryCardView: View {
    let item: InventoryItem

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(item.emoji).font(.system(size: 32))
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 16, weight: .bold))
                    Spacer()
                    HStack(spacing: 6) {
                        Text(item.quantityLabel)
                            .font(.system(size: 14, weight: .semibold))
                        if item.alert {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(Color(hex: "#E86F71"))
                        }
                    }
                }
                ProgressView(value: item.fill)
                    .tint(colorForCategory(item.category))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                if let expires = item.expiresAt, !expires.isEmpty {
                    Text("期限: \(expires)")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
                if let loc = item.location, !loc.isEmpty {
                    Text("場所: \(loc)")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
    }

    private func colorForCategory(_ cat: String) -> Color {
        if cat.contains("肉") || cat.contains("魚") { return Color(hex: "#56ACC7") }
        return Color(hex: "#E57675")
    }
}

struct ScoreRing: View {
    let score: Int
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#BCEFD6").opacity(0.25), lineWidth: 14)
                .frame(width: 160, height: 160)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(Color(hex: "#F3A16E"), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))
            VStack {
                Text("今日の健康スコア").font(.system(size: 14, weight: .bold))
                Text("\(score)点").font(.system(size: 32, weight: .heavy)).foregroundStyle(Color(hex: "#3E4B50"))
            }
        }
    }
}

struct RadarChart: View {
    let values: [Double]
    let labels: [String]

    var body: some View {
        GeometryReader { geo in
            let radius = min(geo.size.width, geo.size.height) / 2 * 0.9
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let sides = max(values.count, 3)
            let labelPairs = Array(zip(0..<sides, labels))

            ZStack {
                ForEach(1..<5) { i in
                    Polygon(sides: sides, scale: Double(i) / 4.0)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
                Polygon(sides: sides, scales: values)
                    .fill(Color(hex: "#BCEFD6").opacity(0.25))
                Polygon(sides: sides, scales: values)
                    .stroke(Color(hex: "#68C29E"), lineWidth: 2)

                ForEach(labelPairs, id: \.0) { pair in
                    let idx = pair.0
                    let text = pair.1
                    let ang = angleFor(index: idx, total: sides)
                    let labelPoint = CGPoint(
                        x: center.x + cos(ang) * radius,
                        y: center.y + sin(ang) * radius
                    )
                    Text(text)
                        .font(.system(size: 12))
                        .position(labelPoint)
                }
            }
        }
    }

    private func angleFor(index: Int, total: Int) -> Double {
        (Double(index) / Double(total)) * 2 * Double.pi - Double.pi / 2
    }
}

struct Polygon: Shape {
    let sides: Int
    var scale: Double = 1.0
    var scales: [Double] = []

    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2 * 0.8
        var path = Path()
        for i in 0..<sides {
            let valueScale = scales.isEmpty ? scale : scales[i]
            let angle = (Double(i) / Double(sides)) * 2 * Double.pi - Double.pi / 2
            let x = center.x + CGFloat(cos(angle) * r * valueScale)
            let y = center.y + CGFloat(sin(angle) * r * valueScale)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) } else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        path.closeSubpath()
        return path
    }
}

struct GuidanceBubble: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "text.bubble")
                .foregroundStyle(Color(hex: "#68C29E"))
            Text(text)
                .font(.system(size: 14, weight: .bold))
            Spacer()
            Image(systemName: "person.circle")
                .foregroundStyle(Color(hex: "#68C29E"))
        }
        .padding(12)
        .background(Color(hex: "#BCEFD6").opacity(0.22))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct MealRow: View {
    let meal: MealLog
    var body: some View {
        HStack {
            Image(systemName: meal.icon)
                .foregroundStyle(Color(hex: "#68C29E"))
            Text("\(meal.time)：\(meal.menu)")
                .font(.system(size: 15, weight: .bold))
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.gray)
        }
        .padding(12)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Helper

extension Color {
    init(hex: String) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hexFormatted.hasPrefix("#") { hexFormatted.remove(at: hexFormatted.startIndex) }
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255
        let b = Double(rgbValue & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
