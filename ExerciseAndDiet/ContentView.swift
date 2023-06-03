//ContentView

import SwiftUI

struct ContentView: View {
    @State var isNavPush = false
    @State var isData = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                if let savedBmi = UserDefaults.standard.value(forKey: "bmi") as? Double{
                    NavigationLink(isActive: $isData) {
                        MainView()
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                }
                
                NavigationLink(isActive: $isNavPush) {
                    StartView()
                        .navigationBarBackButtonHidden(true)
                } label: {}
                
                Spacer()
                
                Image("heartbeat")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                
                Button(action: {
                    isNavPush = true // Set the state to true to trigger navigation
                }) {
                    Text("開始使用")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(10)
                }
                Spacer()
            }
            .navigationTitle("Exercise & Diet")
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
