//
//  PhotosPicker_PhotoUIApp.swift
//  PhotosPicker PhotoUI
//
//  Created by Rizal Hilman on 27/05/24.
//

import SwiftUI
import SwiftData

@main
struct PhotosPicker_PhotoUIApp: App {
    
    var sharedModelContainer: ModelContainer = {
            let scheme = Schema([
                // entities here
                Feed.self
            ])
            
            let modelConfiguration = ModelConfiguration(schema: scheme,
                                                        isStoredInMemoryOnly: false)
            do {
                return try ModelContainer(for: scheme, configurations: modelConfiguration)
            } catch {
                fatalError("Could not create model container \(error)")
            }
        
        }()
        
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
