//
//  teste_pegapegaApp.swift
//  teste-pegapega
//
//  Created by Thayna Rodrigues on 11/11/23.
//

import SwiftUI

@main
struct teste_pegapegaApp: App {
    @StateObject private var multipeerSession = MultipeerService()
    
    var body: some Scene {
        WindowGroup {
            HostView()
                .environmentObject(multipeerSession)
        }
    }
}
