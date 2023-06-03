import SwiftUI
import CoreData

struct MainView: View {
    @State private var currentCaloriesIntake: Double = 0.0
    @State private var bmi: Double = 0.0
    @State private var suggestedCalories: Double = 0
    @State private var isNavPush = false // 控制是否顯示 新增用餐紀錄
    @State private var showDetail = false // 控制是否顯示 詳細用餐紀錄
    @State private var addFoodKcal = false // 控制是否顯示詳細紀錄
    @State private var currentDate = Date()
    @State private var foodListAdded = false // 控制是否接收到通知
    @State private var addFromFoodList = false // 控制是否接收到通知
    
    @FetchRequest(entity: FoodList.entity(), sortDescriptors: [])
    private var foodList: FetchedResults<FoodList>
    
    @State private var selectedFood: FoodList? // 当前选中的Food对象
    
    var body: some View {
        TabView {
            //tab 飲食紀錄 start
            NavigationView {
                VStack {
                    NavigationLink(isActive: $isNavPush) {
                        AddFoodView(selectedFood: $selectedFood) // 将selectedFood传递给AddFoodView
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    NavigationLink(isActive: $showDetail) {
                        ShowDetailView()
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    if bmi != 0.0 {
                        Text("BMI: \(String(format: "%.1f", bmi))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 15)
                            .padding(.leading)
                    }
                    
                    if suggestedCalories != 0.0 {
                        Text("建議大卡攝取量: \(String(format: "%.1f", suggestedCalories))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 15)
                            .padding(.leading)
                    }
                    
                    Text("目前大卡攝取量: \(String(format: "%.1f", currentCaloriesIntake))") // 顯示目前大卡攝取量
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 15)
                        .padding(.leading)
                    
                    HStack {
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
                    
                    Button(action: {
                        showDetail = true
                    }) {
                        Text("詳細紀錄")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top)
                    
                    Spacer() // 將元素推到頂部
                }
                .navigationTitle("飲食紀錄")
                .onAppear {
                    fetchFoodRecords()
                    
                    if let savedBmi = UserDefaults.standard.value(forKey: "bmi") as? Double {
                        bmi = savedBmi
                    }
                    
                    if let savedSuggestedCalories = UserDefaults.standard.value(forKey: "suggestedCalories") as? Double {
                        suggestedCalories = savedSuggestedCalories
                    }
                    
                    currentDate = Date() // 更新當前日期
                }
                
            }
            .tabItem {
                Image(systemName: "doc.text.below.ecg")
                Text("飲食紀錄")
            }
            //tab 飲食紀錄 end
            //========================================
            //tab 添加數據 start
            NavigationView {
                VStack {
                    NavigationLink(isActive: $addFoodKcal) {
                        AddFoodKcalView() // 
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    NavigationLink(isActive: $addFromFoodList) {
                        AddFoodView(selectedFood: $selectedFood) //
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    Spacer()
                    
                    List {
                        ForEach(foodList) { food in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(food.name ?? "")
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", food.calories)) 大卡")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    selectedFood = food // 更新选中的Food对象
                                    addFromFoodList = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .resizable()
                                        .frame(width: 25.0, height: 25.0)
                                        .foregroundColor(.black)
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .background(Color.white)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            addFoodKcal = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 50.0, height: 50.0)
                                .foregroundColor(.black)
                                .padding([.trailing, .bottom], 20)
                        }
                    }
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
            NavigationView {
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
            NavigationView {
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
        .onChange(of: foodListAdded) { _ in
            if foodListAdded {
                refreshFoodList()
                foodListAdded = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("FoodListAdded"))) { _ in
            foodListAdded = true
        }
    }
    
    private func fetchFoodRecords() {
        let request: NSFetchRequest<FoodRecord> = FoodRecord.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: currentDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.predicate = predicate
        
        do {
            let records = try PersistenceController.shared.container.viewContext.fetch(request)
            currentCaloriesIntake = records.reduce(0.0) { $0 + $1.calories }
        } catch {
            print("Error fetching food records: \(error)")
        }
    }
    
    private func fetchFoodList() -> [FoodList] {
        var foodList = [FoodList]()
        
        let request: NSFetchRequest<FoodList> = FoodList.fetchRequest()
        
        do {
            foodList = try PersistenceController.shared.container.viewContext.fetch(request)
        } catch {
            print("Error fetching food list: \(error)")
        }
        
        return foodList
    }
    
    private func refreshFoodList() {
        fetchFoodRecords()
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
