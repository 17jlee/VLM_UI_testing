//
//  ContentView.swift
//  VLM_testing
//
//  Created by Jimin Lee on 08/02/2026.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem{
                    Image(systemName: "house")
                }
            NavigationDemoView()
                .tabItem {
                    Image(systemName: "arrowshape.turn.up.right")
                }
            
            ListDemoView()
                .tabItem {
                    Image(systemName: "list.bullet")
                }
            
            MiscDemoView()
                .tabItem {
                    Image(systemName: "puzzlepiece.extension")
                }
        }
    }
}

private struct HomeView: View {
    var body: some View {
        Text("Hello World!")
            .font(.largeTitle)
    }
}

private struct NavigationDemoView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink(
                    "Push: This Is A Very Long Navigation Link That Will Likely Be Truncated In The List Row",
                    destination: DetailView()
                )
                
                NavigationLink(destination: DetailView()) {
                    Label("Label With An Absurdly, Unnecessarily, Incredibly Long Title That Is Definitely Too Long For Comfort", systemImage: "arrow.right")
                }
            }
            .navigationTitle("This Is The Navigation Demo With A Navigation Title That Is Way Too Long To Fit")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ToolbarItem With Another Incredibly Long Title To Check Truncation")
                        .lineLimit(1)
                }
            }
        }
    }
    
    private struct DetailView: View {
        @State private var showingAlert = false
        
        var body: some View {
            VStack(spacing: 24) {
                Text("Detail View Title With A Title That Overflows The Usual Width Of The Navigation Bar")
                    .font(.title2)
                    .lineLimit(1)
                
                Text("Here is some very, very, very, very, very, very, very, very, very, very, very long detail text that will probably need to wrap or get truncated depending on the available space.")
                    .padding()
                
                Button("Show Alert With Extremely Long Text That Will Most Certainly Not Fit On One Line, So We Can See How Alerts Handle It") {
                    showingAlert = true
                }
                .alert("This Is An Alert With A Ludicrously Long Title That Will Probably Get Truncated, Especially On Small Screens", isPresented: $showingAlert) {
                    Button("Dismiss This Incredibly Long Button Title For The Alert", role: .cancel) {}
                }
            }
            .navigationTitle("Detail: Overly Long Navigation Title")
        }
    }
}

private struct ListDemoView: View {
    var body: some View {
        List {
            Section(header: Text("Section Header With A Title That Is Absurdly, Excessively, And Almost Comically Long")) {
                ForEach(1..<6) { i in
                    Text("Row #\(i): This Is An Excessively Verbose And Unreasonably Long Piece Of Text Used As A List Row Title")
                        .lineLimit(1)
                }
            }
            
            Section(header: Text("Another Section With A Ridiculously Long Header That Will Probably Wrap")) {
                ForEach(6..<11) { i in
                    HStack {
                        Image(systemName: "star")
                        Text("Another Very Long Row Title To See If The Text Gets Truncated Or Wrapped Depending On The Device Size (Row #\(i))")
                    }
                }
            }
        }
        .navigationTitle("ListDemo With A Navigation Title That Is Far Too Long For Its Own Good")
    }
}

private struct MiscDemoView: View {
    @State private var text: String = "This text field has a really long placeholder that might not fit in the visible frame of the field, so let's see what happens!"
    @State private var showSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Form Section With A Comedically Long Header Title That Is Bound To Cause Truncation")) {
                    
                    TextField("Type here: This is a very, very, very, very, very, very, very, very, very long placeholder!", text: $text)
                        .textFieldStyle(.roundedBorder)
                    
                    Button(action: { showSheet = true }) {
                        Label("Button With An Extremely, Almost Ridiculously Long Label For Maximum UI Truncation Testing", systemImage: "rectangle.and.pencil.and.ellipsis")
                            .lineLimit(1)
                    }
                    .sheet(isPresented: $showSheet) {
                        VStack(spacing: 24) {
                            Text("Sheet Title With An Obscenely Long String That Probably Won't Fit On One Line")
                                .font(.headline)
                                .padding()
                            
                            Text("This is the content of a sheet with a very, very, very, very, very, very, very, very long string inside it.")
                                .multilineTextAlignment(.leading)
                                .padding()
                            
                            Button("Dismiss This Sheet With A Very Long Button Title For Fun", role: .cancel) {
                                showSheet = false
                            }
                        }
                        .presentationDetents([.medium, .large])
                    }
                }
            }
            .navigationTitle("Miscellaneous Tab With A Ridiculously Long Navigation Title That Should Be Truncated")
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Text("ToolbarItem With Another Outrageously Long String To Test Truncation Behavior In The Toolbar")
                        .lineLimit(1)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(\.locale, .init(identifier: "de"))
}
