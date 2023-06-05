//ContentView

import SwiftUI

struct ContentView: View {
    @State var isNavPush = false
    @State var isData = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                //檢測是否有輸入過資料，如果有資料就跳轉MainView頁面
                if let savedBmi = UserDefaults.standard.value(forKey: "bmi") as? Double{
                    NavigationLink(isActive: $isData) {
                        MainView()
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                }
                
                //點擊“開始使用”Button後跳轉StartView
                NavigationLink(isActive: $isNavPush) {
                    StartView()
                        .navigationBarBackButtonHidden(true)
                } label: {}
                
                //空行
                Spacer()
                
                //Logo
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
            .navigationTitle("Exercise & Diet")//左上角的Title
            .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
