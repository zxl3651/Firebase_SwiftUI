//
//  FirebaseAPI_SwiftUIApp.swift
//  FirebaseAPI_SwiftUI
//
//  Created by 이성현 on 2023/10/26.
//

import SwiftUI
import FirebaseCore

@main
struct FirebaseAPI_SwiftUIApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
