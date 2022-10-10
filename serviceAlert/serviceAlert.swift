//
//  serviceAlert.swift
//  serviceAlert
//
//  Created by Andy Lin on 2/18/21.
//

import WidgetKit
import SwiftUI
import Intents

struct ServiceChangeEntry: TimelineEntry{
    let date = Date()
    let routesWithIssues: Set<String>
}

struct Provider: TimelineProvider{
    @AppStorage("routesWithIssues", store: UserDefaults(suiteName: "group.com.andylin.service-alerts-swiftui"))
    var routesWithIssuesSaved: Data = Data()
    
    func getSnapshot(in context: Context, completion: @escaping (ServiceChangeEntry) -> Void) {
        guard let data = try? JSONDecoder().decode(Set<String>.self, from: routesWithIssuesSaved) else {return}
        print(data)
        let entry = ServiceChangeEntry(routesWithIssues: data)
        completion(entry)
    }
    
    func placeholder(in context: Context) -> ServiceChangeEntry {
        return ServiceChangeEntry(routesWithIssues: [])
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ServiceChangeEntry>) -> Void) {
        guard let data = try? JSONDecoder().decode(Set<String>.self, from: routesWithIssuesSaved) else {return}
        let entry = ServiceChangeEntry(routesWithIssues: data)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct WidgetEntryView: View{
    let entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family
    
    @ViewBuilder
    var body: some View{
        switch family{
        case .systemSmall:
            VStack{
                Text(entry.routesWithIssues.count == 0 ? "No lines with issue" : "\(entry.routesWithIssues.count) lines with issues")
                LazyVGrid(columns: [GridItem(.fixed(20)), GridItem(.fixed(20)), GridItem(.fixed(20)), GridItem(.fixed(20)), GridItem(.fixed(20))], spacing: 0){
                    ForEach(Array(Set(entry.routesWithIssues)), id: \.self){ entries in
                        RouteShape(route: entries, color: routeColors[entries] ?? "#000000", size: 20)
                    }
                }
            }
        case .systemMedium:
            VStack{
            Text(entry.routesWithIssues.count == 0 ? "No lines with issue" : "\(entry.routesWithIssues.count)lines with issues")
                LazyVGrid(columns: [GridItem(.fixed(30)), GridItem(.fixed(30)), GridItem(.fixed(30)), GridItem(.fixed(30)), GridItem(.fixed(30)), GridItem(.fixed(30)), GridItem(.fixed(30))], spacing: 10){
                    ForEach(Array(Set(entry.routesWithIssues)), id: \.self){ entries in
                        RouteShape(route: entries, color: routeColors[entries] ?? "#000000", size: 30)
                    }
                }
            }
        default:
            VStack{
            Text(entry.routesWithIssues.count == 0 ? "No lines with issue" : "\(entry.routesWithIssues.count) lines with issues")
                .font(.title)
                LazyVGrid(columns: [GridItem(.fixed(45)), GridItem(.fixed(45)), GridItem(.fixed(45)), GridItem(.fixed(45)), GridItem(.fixed(45))], spacing: 10){
                    ForEach(Array(Set(entry.routesWithIssues)), id: \.self){ entries in
                        RouteShape(route: entries, color: routeColors[entries] ?? "#000000", size: 45)
                    }
                }
            }
        }
    }
}

@main
struct serviceAlert: Widget{
    private let kind = "service_change_overall_widget"
    
    var body: some WidgetConfiguration{
        StaticConfiguration(kind: kind, provider: Provider()){
            entry in
            WidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .configurationDisplayName("Service Change Widget")
        .description("Shows what lines have service issues.")
    }
}
