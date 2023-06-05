import SwiftUI
import CoreData
import HealthKit

struct MainView: View {
    @State private var currentCaloriesIntake: Double = 0.0
    @State private var bmi: Double = 0.0
    @State private var suggestedCalories: Double = 0
    @State private var isNavPush = false // 控制是否顯示 新增用餐紀錄
    @State private var shouldLogout = false //logout
    @State private var showDetail = false // 控制是否顯示 詳細用餐紀錄
    @State private var addFoodKcal = false // 控制是否顯示詳細紀錄
    @State private var currentDate = Date()//儲存日期
    @State private var foodListAdded = false // 控制是否接收到通知
    @State private var addFromFoodList = false // 控制是否接收到通知
    
    //以下是用來存取HealthKit的變數
    @State private var stepCount: Double = 0
    @State private var distance: Double = 0
    @State private var activeEnergyBurned: Double = 0
    @State private var standHours: Double = 0
    @State private var exerciseHours: TimeInterval = 0
    
    private var healthStore = HKHealthStore()
        
    //讀取CoreData FoodList
    @FetchRequest(entity: FoodList.entity(), sortDescriptors: [])
    private var foodList: FetchedResults<FoodList>
    
    @State private var selectedFood: FoodList? // 当前选中的Food对象
    
    var body: some View {
        TabView {
            //tab 飲食紀錄 start
            NavigationView {
                VStack {
                    //跳轉新增用餐紀錄頁面（AddFoodView）
                    NavigationLink(isActive: $isNavPush) {
                        AddFoodView(selectedFood: $selectedFood) // 将selectedFood传递给AddFoodView
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    //跳轉詳細用餐紀錄頁面（ShowDetailView）
                    NavigationLink(isActive: $showDetail) {
                        ShowDetailView()
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    //顯示Bmi
                    if bmi != 0.0 {
                        Text("BMI: \(String(format: "%.1f", bmi))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 15)
                            .padding(.leading)
                    }
                    
                    //顯示建議大卡攝取量
                    if suggestedCalories != 0.0 {
                        Text("建議大卡攝取量: \(String(format: "%.1f", suggestedCalories))")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 15)
                            .padding(.leading)
                    }
                    
                    //目前大卡攝取量
                    Text("目前大卡攝取量: \(String(format: "%.1f", currentCaloriesIntake))") // 顯示目前大卡攝取量
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 15)
                        .padding(.leading)
                    
                    HStack {
                        //進度條
                        ProgressView(value: Double(currentCaloriesIntake), total: Double(suggestedCalories)) // 進度條
                            .accentColor(Color.green)
                            .scaleEffect(x: 1, y: 8)
                            .padding([.leading,.top,.bottom])
                        
                        //新增飲食紀錄Button
                        Button(action: {
                            isNavPush = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 25.0, height: 25.0)
                                .foregroundColor(.black)
                                .padding([.trailing,.top,.bottom])
                        }
                    }
                    
                    //詳細飲食紀錄Button
                    Button(action: {
                        showDetail = true
                    }) {
                        Text("飲食紀錄")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                    
                    Spacer() // 將元素推到頂部
                }
                .navigationTitle("飲食紀錄")
                .onAppear {//進入頁面時首先加載的數據
                    fetchFoodRecords()//讀取飲食紀錄的Database（CoreData）
                    
                    if let savedBmi = UserDefaults.standard.value(forKey: "bmi") as? Double {
                        bmi = savedBmi//讀取bmi
                    }
                    
                    if let savedSuggestedCalories = UserDefaults.standard.value(forKey: "suggestedCalories") as? Double {
                        suggestedCalories = savedSuggestedCalories
                    }//讀取建議大卡攝取量
                    
                    currentDate = Date() // 更新當前日期
                }
                
            }
            .tabItem {
                Image(systemName: "doc.text.below.ecg")
                Text("飲食紀錄")
            }
            //tab 飲食紀錄 end
            //================================================================================
            //tab 添加數據 start
            NavigationView {
                VStack {
                    //跳轉頁面，新建食物頁面
                    NavigationLink(isActive: $addFoodKcal) {
                        AddFoodKcalView() // 
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    //跳轉頁面，新建用餐紀錄頁面
                    NavigationLink(isActive: $addFromFoodList) {
                        AddFoodView(selectedFood: $selectedFood) //
                            .navigationBarBackButtonHidden(true)
                    } label: {}
                    
                    Spacer()
                    
                    //List 顯示CoreData FoodList的數據
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
                                
                                //List右邊的“+”Button
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
                    .listStyle(PlainListStyle())//List 的style
                    .background(Color.white)//List背景顏色
                    
                    HStack {
                        Spacer()
                        
                        //右下角的“+”Button 用於增加FoodList數據
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
            //================================================================================
            //tab 運動紀錄 start
            NavigationView {
                VStack {
                    Text("步数: \(stepCount)")
                    Text("距离: \(distance)")
                    Text("活动: \(activeEnergyBurned)")
                    Text("站立时间: \(standHours)")
                    Text("运动时间: \(exerciseHours)")
                }
                .navigationTitle("運動紀錄")
            }
            .tabItem {
                Image(systemName: "figure.run")
                Text("運動紀錄")
            }
            .onAppear {
                requestHealthKitAuthorization()
                getStepCount()
                getDistance()
                getActiveEnergyBurned()
                getStandHours()
                getExerciseHours()
            }
            //tab 運動紀錄 end
            //================================================================================
            //tab 個人資訊 start
            NavigationView {
                VStack {
                    
                    //登出Button
                    Button(action: {
                        resetAppData()
                        shouldLogout = true
                    }) {
                        Text("登出")
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(10)
                    }
                }
                .navigationTitle("個人資訊")
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("個人資訊")
            }
            .fullScreenCover(isPresented: $shouldLogout) {
                ContentView()
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
    
    //讀取飲食紀錄的func （FoodRecord CoreData）
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
    
    //新建食物的func （FoodList CoreData）
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
    
    private func requestHealthKitAuthorization() {
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .appleStandTime)!,
            HKObjectType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { (success, error) in
            if success {
                print("HealthKit authorization request successful.")
            } else {
                if let error = error {
                    print("HealthKit authorization error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func getStepCount() {
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: nil, options: .cumulativeSum) { (_, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let stepCount = sumQuantity.doubleValue(for: HKUnit.count())
                DispatchQueue.main.async {
                    self.stepCount = stepCount
                }
            } else {
                if let error = error {
                    print("Failed to fetch step count: \(error.localizedDescription)")
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func getDistance() {
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: nil, options: .cumulativeSum) { (_, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let distanceInMeters = sumQuantity.doubleValue(for: HKUnit.meter())
                DispatchQueue.main.async {
                    self.distance = distanceInMeters
                }
            } else {
                if let error = error {
                    print("Failed to fetch distance: \(error.localizedDescription)")
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func getActiveEnergyBurned() {
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: nil, options: .cumulativeSum) { (_, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let energy = sumQuantity.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self.activeEnergyBurned = energy
                }
            } else {
                if let error = error {
                    print("Failed to fetch active energy burned: \(error.localizedDescription)")
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func getStandHours() {
        let standType = HKQuantityType.quantityType(forIdentifier: .appleStandTime)!
        let query = HKStatisticsQuery(quantityType: standType, quantitySamplePredicate: nil, options: .cumulativeSum) { (_, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let standHours = sumQuantity.doubleValue(for: HKUnit.minute()) / 60
                DispatchQueue.main.async {
                    self.standHours = standHours
                }
            } else {
                if let error = error {
                    print("Failed to fetch stand hours: \(error.localizedDescription)")
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func getExerciseHours() {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: .other)
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (_, samples, error) in
            if let workouts = samples as? [HKWorkout] {
                let exerciseHours = workouts.reduce(0.0) { $0 + $1.duration }
                DispatchQueue.main.async {
                    self.exerciseHours = exerciseHours
                }
            } else {
                if let error = error {
                    print("Failed to fetch exercise hours: \(error.localizedDescription)")
                }
            }
        }
        healthStore.execute(query)
    }
    
    private func resetAppData() {
        // 删除Core Data中的所有对象
        deleteAllFoodRecordsAndList()
        
        // 重置偏好设置（UserDefaults）
        UserDefaults.standard.removeObject(forKey: "bmi")
        UserDefaults.standard.removeObject(forKey: "suggestedCalories")
        UserDefaults.standard.removeObject(forKey: "weight")
        UserDefaults.standard.removeObject(forKey: "height")
    }

    private func deleteAllFoodRecordsAndList() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "FoodRecord")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try PersistenceController.shared.container.viewContext.execute(deleteRequest)
        } catch {
            print("Error deleting food records: \(error)")
        }
        
        let fetchRequest1: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "FoodList")
        let deleteRequest1 = NSBatchDeleteRequest(fetchRequest: fetchRequest1)
        
        do {
            try PersistenceController.shared.container.viewContext.execute(deleteRequest1)
        } catch {
            print("Error deleting food list: \(error)")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
