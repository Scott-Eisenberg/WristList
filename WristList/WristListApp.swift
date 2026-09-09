//
//  WristListApp.swift
//  WristList
//
//  Created by Scott Eisenberg on 9/7/26.
//

import SwiftData
import SwiftUI

@main
struct WristListApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema(WristlistDataController.schemaModels)
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
