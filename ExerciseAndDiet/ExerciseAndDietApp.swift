//
//  ExerciseAndDietApp.swift
//  ExerciseAndDiet
//
//  Created by xuan on 2023/6/3.
//

import SwiftUI

@main
struct ExerciseAndDietApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
