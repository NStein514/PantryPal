// PantryPal "Use it up" widget (WidgetKit), built by the PantryWidgetExtension target.
//
// The app writes a JSON payload into the shared App Group (lib/services/home_widget_service.dart):
// item names, quantities, ISO expiry dates and pre-translated labels. Days-left is computed
// here against the timeline entry's date, and the timeline reloads after midnight, so the
// widget stays right even if the app isn't opened.

import SwiftUI
import WidgetKit

/// From Info.plist (set in ios/Flutter/Identity.xcconfig); must match HomeWidgetService.appGroupId.
private let appGroupId = Bundle.main.object(forInfoDictionaryKey: "PantryPalAppGroup") as? String ?? "group.app.pantrypal"
private let dataKey = "pantry_widget"

struct Payload: Decodable {
    struct Item: Decodable {
        let name: String
        let qty: String
        let expiry: String
        let id: Int?
        let useOne: Bool?
    }

    let title: String
    let recipes: String
    let empty: String
    let expired: String
    let expiredLabel: String
    let usedLabel: String?
    let soonLabel: String
    let soonDays: Int
    let horizonDays: Int
    let days: [String: String]
    let items: [Item]
}

struct Row: Identifiable {
    let id = UUID()
    let name: String
    let qty: String
    let days: Int
    let itemId: Int?
    let useOne: Bool
}

struct PantryEntry: TimelineEntry {
    let date: Date
    let payload: Payload?
}

struct PantryProvider: TimelineProvider {
    func placeholder(in context: Context) -> PantryEntry {
        PantryEntry(date: Date(), payload: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (PantryEntry) -> Void) {
        completion(load(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PantryEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        // One entry now and one at midnight, so "today"/"1 day" roll over on time.
        let entries = [load(at: now), load(at: midnight)]
        completion(Timeline(entries: entries, policy: .after(midnight)))
    }

    private func load(at date: Date) -> PantryEntry {
        let raw = UserDefaults(suiteName: appGroupId)?.string(forKey: dataKey)
        let payload = raw.flatMap { try? JSONDecoder().decode(Payload.self, from: Data($0.utf8)) }
        return PantryEntry(date: date, payload: payload)
    }
}

private let isoDay: DateFormatter = {
    let f = DateFormatter()
    f.calendar = Calendar(identifier: .gregorian)
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = "yyyy-MM-dd"
    return f
}()

private func rows(_ p: Payload, on date: Date) -> [Row] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: date)
    return p.items.compactMap { item in
        guard let expiry = isoDay.date(from: item.expiry),
              let days = calendar.dateComponents([.day], from: today, to: calendar.startOfDay(for: expiry)).day
        else { return nil }
        return Row(name: item.name, qty: item.qty, days: days, itemId: item.id, useOne: item.useOne ?? false)
    }.sorted { $0.days < $1.days }
}

private func color(_ days: Int, soonDays: Int) -> Color {
    if days < 0 { return Color(red: 0.83, green: 0.18, blue: 0.18) }
    if days <= soonDays { return Color(red: 0.94, green: 0.42, blue: 0.0) }
    return Color(red: 0.22, green: 0.56, blue: 0.24)
}

struct PantryWidgetView: View {
    let entry: PantryEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        content
            .widgetURL(URL(string: "pantrypal://pantry?homeWidget"))
            .widgetBackground()
    }

    @ViewBuilder private var content: some View {
        if let p = entry.payload {
            let all = rows(p, on: entry.date)
            let expired = all.filter { $0.days < 0 }.count
            let soon = all.filter { $0.days >= 0 && $0.days <= p.soonDays }.count
            let shown = Array(all.filter { $0.days <= p.horizonDays }.prefix(family == .systemSmall ? 3 : 4))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(p.title).font(.headline).lineLimit(1)
                    Spacer(minLength: 4)
                    if family != .systemSmall, let url = URL(string: "pantrypal://recipes?homeWidget") {
                        Link(destination: url) {
                            Text(p.recipes)
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                        }
                    }
                }
                let summary = [
                    expired > 0 ? "\(p.expiredLabel): \(expired)" : nil,
                    soon > 0 ? "\(p.soonLabel): \(soon)" : nil,
                ].compactMap { $0 }.joined(separator: " · ")
                if !summary.isEmpty {
                    Text(summary).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                if shown.isEmpty {
                    Text(p.empty).font(.subheadline).foregroundStyle(.secondary)
                } else {
                    ForEach(shown) { row in
                        HStack {
                            Text(row.qty.isEmpty ? row.name : "\(row.name) \(row.qty)")
                                .font(.subheadline).lineLimit(1)
                            Spacer(minLength: 4)
                            Text(row.days < 0 ? p.expired : (p.days[String(row.days)] ?? ""))
                                .font(.caption.weight(.bold))
                                .foregroundStyle(color(row.days, soonDays: p.soonDays))
                            if row.useOne, let itemId = row.itemId {
                                UseOneButton(itemId: itemId, label: "\(p.usedLabel ?? ""): \(row.name)")
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("PantryPal").font(.headline)
                Text("Open PantryPal to load your pantry").font(.subheadline).foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
        }
    }
}

/// The per-row "used one" button. Interactive widgets need iOS 17; earlier versions show nothing.
struct UseOneButton: View {
    let itemId: Int
    let label: String

    var body: some View {
        if #available(iOS 17.0, *) {
            Button(intent: UseOneIntent(itemId: itemId)) {
                Image(systemName: "checkmark.circle")
                    .font(.subheadline)
                    .foregroundStyle(Color.green)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
        }
    }
}

private extension View {
    /// iOS 17 requires containerBackground; earlier versions draw their own padding/background.
    @ViewBuilder func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) { Color(UIColor.systemBackground) }
        } else {
            padding().background(Color(UIColor.systemBackground))
        }
    }
}

@main
struct PantryWidget: Widget {
    /// Must match HomeWidgetService.iOSName.
    let kind = "PantryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PantryProvider()) { entry in
            PantryWidgetView(entry: entry)
        }
        .configurationDisplayName("PantryPal")
        .description("What to use up first")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
