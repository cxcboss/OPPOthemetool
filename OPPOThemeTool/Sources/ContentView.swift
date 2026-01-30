import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            UnpackView()
                .tabItem {
                    Label("解包", systemImage: "folder.badge.minus")
                }
                .tag(0)
            
            PackView()
                .tabItem {
                    Label("打包", systemImage: "folder.badge.plus")
                }
                .tag(1)
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    ContentView()
}
