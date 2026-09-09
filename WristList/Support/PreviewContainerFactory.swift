//
//  PreviewContainerFactory.swift
//  WristList
//

import SwiftData

@MainActor
enum PreviewContainerFactory {
    static func makeContainer() -> ModelContainer {
        let schema = Schema(WristlistDataController.schemaModels)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)

        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            try WristlistDataController.seedIfNeeded(in: container.mainContext)
            return container
        } catch {
            fatalError("Could not create preview container: \(error)")
        }
    }
}
