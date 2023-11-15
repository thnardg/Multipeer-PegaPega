//
//  ContentView2.swift
//  Multipeer-PegaPega
//
//  Created by Leonardo Mota on 15/11/23.
//

import SwiftUI

struct ContentView2: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    ContentView2()
}


class ContentView2ViewModel: ObservableObject {
    @Published var greetingText = "Hello, World!"
    @Published var lobbyMembers: [PlayerInfo]?
    
    func updateGreeting() {
        greetingText = "Greetings from ViewModel!"
    }
}
