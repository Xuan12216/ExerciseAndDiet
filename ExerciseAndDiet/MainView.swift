import SwiftUI
import CoreData

struct MainView: View {
    @State private var currentCaloriesIntake: Double = 0.0
    @State private var bmi: Double = 0.0
    @State private var suggestedCalories: Double = 0
    @State private var isNavPush = false
    
    var body: some View {
        TabView {
            //tab 飲食紀錄 start
            NavigationView{
                VStack {
                    NavigationLink(isActive: $isNavPush) {
                        AddFoodView()
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    if bmi != 0.0 {
                        Text("BMI: \(String(format: "%.1f", bmi))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top,15)
                            .padding(.leading)
                    }
                    
                    if suggestedCalories != 0.0 {
                        Text("建議大卡攝取量: \(String(format: "%.1f", suggestedCalories))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top,15)
                            .padding(.leading)
                    }
                    
                    Text("目前大卡攝取量: \(String(format: "%.1f", currentCaloriesIntake))") // 顯示目前大卡攝取量
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top,15)
                        .padding(.leading)
                    
                    HStack{
                        ProgressView(value: Double(currentCaloriesIntake), total: Double(suggestedCalories)) // 進度條
                            .accentColor(Color.green)
                            .scaleEffect(x: 1, y: 8)
                            .padding()
                        
                        Button(action: {
                            isNavPush = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 25.0, height: 25.0)
                                .foregroundColor(.black)
                                .padding()
                        }
                    }
                    
                    Spacer() // 將元素推到頂部
                }
                .navigationTitle("飲食紀錄")
                .onAppear {
                    fetchFoodRecords()
                    
                    if let savedBmi = UserDefaults.standard.value(forKey: "bmi") as? Double {
                        bmi = savedBmi
                    }
                    
                    if let savedSuggestedCalories = UserDefaults.standard.value(forKey: "suggestedCalories") as? Double{
                        suggestedCalories = savedSuggestedCalories
                    }
                }
            }
            .tabItem {
                Image(systemName: "doc.text.below.ecg")
                Text("飲食紀錄")
            }
            //tab 飲食紀錄 end
            //========================================
            //tab 添加數據 start
            NavigationView{
                VStack {
                    
                }
                .navigationTitle("添加數據")
            }
            .tabItem {
                Image(systemName: "doc.badge.plus")
                Text("添加數據")
            }
            //tab 添加數據 end
            //========================================
            //tab 運動紀錄 start
            NavigationView{
                VStack {
                    
                }
                .navigationTitle("運動紀錄")
            }
            .tabItem {
                Image(systemName: "figure.run")
                Text("運動紀錄")
            }
            //tab 運動紀錄 end
            //========================================
            //tab 個人資訊 start
            NavigationView{
                VStack {
                    
                }
                .navigationTitle("個人資訊")
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("個人資訊")
            }
            //tab 個人資訊 end
        }
    }
    
    private func fetchFoodRecords() {
        let request: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
        
        do {
            let records = try PersistenceController.shared.container.viewContext.fetch(request)
            currentCaloriesIntake = records.reduce(0.0) { $0 + $1.calories }
        } catch {
            print("Error fetching food records: \(error)")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
