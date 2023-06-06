import SwiftUI
import CoreData
import HealthKit

struct MainView: View {
    @State private var currentCalories: Double = 0.0 //目前攝取大卡量
    @State private var suggestedCalories: Double = 0 //建議攝取大卡量
    @State private var currentMinusConsumeCalories: Double = 0 //
    @State private var consumeCalories: Double = 0//消耗大卡量
    @State private var bmi: Double = 0.0
    @State private var isNavPush = false // 控制是否顯示 新增用餐紀錄
    @State private var isDataLoaded = false
    @State private var shouldLogout = false //logout
    @State private var showDetail = false // 控制是否顯示 詳細用餐紀錄
    @State private var addFoodKcal = false // 控制是否顯示詳細紀錄
    @State private var currentDate = Date()//儲存日期
    @State private var foodListAdded = false // 控制是否接收到通知
    @State private var addFromFoodList = false // 控制是否接收到通知
    @State private var showWeightInput: Bool = false
    @State private var weight: Double = 0.0
    @State private var showHeightInput: Bool = false
    @State private var height: Double = 0.0
    //以下是用來存取HealthKit的變數
    @State private var stepCount: Double = 0
    @State private var distance: Double = 0
    @State private var activeEnergyBurned: Double = 0
    @State private var basalEnergyBurned: Double = 0
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
                VStack (spacing: 20){
                    //顯示Bmi
                    if bmi != 0.0 {
                        createCardView(title: "BMI", value: "\(String(format: "%.1f", bmi))")
                            .padding([.leading,.trailing,.top])
                    }
    
                    //顯示建議大卡攝取量
                    if suggestedCalories != 0.0 {
                        createCardView(title: "建議大卡攝取量", value: "\(String(format: "%.1f", suggestedCalories))")
                            .padding([.leading,.trailing])
                    }
                    
                    //目前大卡攝取量
                    createCardView(title: "目前大卡攝取量", value: "\(String(format: "%.1f", currentCalories))")
                        .padding([.leading,.trailing])
                    
                    
                    if isDataLoaded {
                        createCardView(title: "消耗的總大卡量", value: "\(String(format: "%.1f", consumeCalories))")
                            .padding([.leading, .trailing])
                        
                        createCardView(title: "攝取 - 消耗的大卡量", value: "\(String(format: "%.1f", currentMinusConsumeCalories))")
                            .padding([.leading, .trailing])
                        
                        HStack {
                            //進度條
                            if(currentMinusConsumeCalories > suggestedCalories){
                                ProgressView(value: Double(currentMinusConsumeCalories), total: Double(suggestedCalories)) // 進度條
                                    .accentColor(Color.red)
                                    .scaleEffect(x: 1, y: 8)
                                    .padding([.leading,.top,.bottom])
                                
                            }
                            else if(currentMinusConsumeCalories < 0){
                                ProgressView(value: Double(0), total: Double(suggestedCalories)) // 進度條
                                    .accentColor(Color.green)
                                    .scaleEffect(x: 1, y: 8)
                                    .padding([.leading,.top,.bottom])
                                
                            }
                            else{
                                ProgressView(value: Double(currentMinusConsumeCalories), total: Double(suggestedCalories)) // 進度條
                                    .accentColor(Color.green)
                                    .scaleEffect(x: 1, y: 8)
                                    .padding([.leading,.top,.bottom])
                            }
                            
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
                            
                            .sheet(isPresented: $isNavPush) {
                                AddFoodView(selectedFood: $selectedFood)
                            }
                            
                            .sheet(isPresented: $showDetail) {
                                ShowDetailView()
                            }
                        }
                    } else {
                        Text("正在加載數據...")
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
                    requestHealthKitAuthorization()
                    getActiveEnergyBurned()
                    readBasalEnergyBurned()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        // 加载数据并计算 consumeCalories 和 currentMinusConsumeCalories 的值
                        consumeCalories = activeEnergyBurned + basalEnergyBurned
                        currentMinusConsumeCalories = currentCalories - consumeCalories
                        isDataLoaded = true
                    }

                    fetchFoodRecords()//讀取飲食紀錄的Database（CoreData）
                    
                    if let savedWeight = UserDefaults.standard.value(forKey: "weight") as? Double {
                        weight = savedWeight
                    }
                    
                    if let savedHeight = UserDefaults.standard.value(forKey: "height") as? Double {
                        height = savedHeight
                    }
                    
                    currentDate = Date() // 更新當前日期
                    calculateBMI()
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
                    
                    Spacer()
                    .sheet(isPresented: $addFoodKcal){
                        AddFoodKcalView()
                    }
                    //跳轉頁面，新建用餐紀錄頁面
                    .sheet(isPresented: $addFromFoodList){
                        AddFoodView(selectedFood: $selectedFood)
                    }
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
                VStack(spacing: 20) {
                    createCardView(title: "步行", value: "\(stepCount)")
                    createCardView(title: "步行 + 跑步距离", value: "\(distance)")
                    createCardView(title: "動態能量", value: "\(activeEnergyBurned)")
                    createCardView(title: "靜態能量", value: "\(basalEnergyBurned)")
                    createCardView(title: "站立时间", value: "\(standHours)")
                    Spacer()
                }
                .padding()
                .navigationTitle("運動紀錄")
            }
            .tabItem {
                Image(systemName: "figure.run")
                Text("運動紀錄")
            }
            .onAppear {
                getStepCount()
                getDistance()
                getActiveEnergyBurned()
                readBasalEnergyBurned()
                getStandHours()
            }


            //tab 運動紀錄 end
            //================================================================================
            //tab 個人資訊 start
            NavigationView {
                VStack {
                    VStack{
                        HStack {
                                    if showHeightInput {
                                        TextField("Height (in cm)", value: $height, formatter: NumberFormatter())
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .padding()
                                    } else {
                                        Text("Height: \(String(format: "%.1f", (UserDefaults.standard.value(forKey: "height") as! Double)))cm")
                                            .font(.headline)
                                            .padding()
                                    }
                                    Spacer()
                                    Button(action: toggleHeightInput) {
                                        Text(showHeightInput ? "Save" : "+")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                    }
                                }.padding()
                                .onChange(of: height) { newValue in
                                    UserDefaults.standard.set(newValue, forKey: "height")
                                }
                        
                        HStack {
                                    if showWeightInput {
                                        TextField("Weight (in kg)", value: $weight, formatter: NumberFormatter())
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                            .padding()
                                    } else {
                                        Text("Weight: \(String(format: "%.1f", (UserDefaults.standard.value(forKey: "weight") as! Double))) kg")
                                            .font(.headline)
                                            .padding()
                                    }
                                    Spacer()
                                    Button(action: toggleWeightInput) {
                                        Text(showWeightInput ? "Save" : "+")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                    }
                        }.padding()
                         .onChange(of: weight) { newValue in
                                    UserDefaults.standard.set(newValue, forKey: "weight")
                                }
                    }
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
    
    //================================================================================
    //func
    
    //BMI計算
    private func calculateBMI() {
        
        let heightInMeter = height / 100
        bmi = weight / (heightInMeter * heightInMeter)
        calculateCalories()
    }
    
    private func calculateCalories() {
        // 根據BMI計算建議攝取熱量（大卡）
        let caloriesPerBMIUnit = 1250
        suggestedCalories = Double(bmi * Double(caloriesPerBMIUnit) / 10)
    }
    
    private func toggleHeightInput() {
            showHeightInput.toggle()
        }
    private func toggleWeightInput() {
            showWeightInput.toggle()
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
            currentCalories = records.reduce(0.0) { $0 + $1.calories }
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
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
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
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepCountType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
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
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: distanceType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
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
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
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
    
    func readBasalEnergyBurned() {
        // 创建静态能量消耗类型
        let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        
        // 创建查询谓词，限制为今天
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        
        // 创建查询，获取静态能量消耗数据
        let query = HKStatisticsQuery(quantityType: basalEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
            if let sumQuantity = result?.sumQuantity() {
                let energy = sumQuantity.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self.basalEnergyBurned = energy
                }
            } else {
                if let error = error {
                    print("Failed to fetch active energy burned: \(error.localizedDescription)")
                }
            }
        }
        // 执行查询
        healthStore.execute(query)
    }
    
    private func getStandHours() {
        let standType = HKQuantityType.quantityType(forIdentifier: .appleStandTime)!
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: standType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
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
    
    func createCardView(title: String, value: String) -> some View {
        Text("\(title): \(value)")
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
