import SwiftUI
import CoreData

struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedFood: FoodList?
    
    @State private var name: String = ""
    @State private var calories: Double?
    @State private var quantity: Int = 1
    @State private var currentDate = Date()
    @State private var currentTime = Date()
    @State private var showAlert = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodList.name, ascending: true)],
        animation: .default)
    private var foodList: FetchedResults<FoodList>
    
    var maximumDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack {
                    HStack {
                        Text("名稱")
                            .padding([.top, .leading, .bottom])
                        
                        TextField("輸入食物名稱", text: $name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding([.top, .trailing, .bottom])
                    }
                    
                    if !foodList.filter({ food in
                        return food.name?.contains(name) ?? false
                    }).isEmpty {
                        HStack{
                            Text("相關結果：")
                                .padding(.leading)
                            Spacer()
                        }
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 10) {
                                ForEach(foodList.filter { food in
                                    return food.name?.contains(name) ?? false
                                }, id: \.self) { food in
                                    CardView(food: food)
                                        .onTapGesture {
                                            selectedFood = food
                                            name = food.name ?? ""
                                            calories = food.calories
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(height: 100)
                    }
                    
                    HStack {
                        Text("熱量")
                            .padding([.top, .leading, .bottom])
                        
                        TextField("輸入食物的熱量", value: $calories, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding([.top, .trailing, .bottom])
                    }
                    
                    HStack {
                        Text("數量")
                            .padding()
                        Spacer()
                        Button(action: {
                            if quantity > 1 {
                                quantity -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                        
                        Text("\(quantity)")
                            .font(.title3)
                            .padding()
                        
                        Button(action: {
                            quantity += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.black)
                        }
                        .padding(.trailing)
                    }
                    
                    DatePicker("日期", selection: $currentDate, in: ...maximumDate, displayedComponents: .date)
                        .padding()
                    
                    DatePicker("時間", selection: $currentTime, displayedComponents: .hourAndMinute)
                        .padding()
                    
                    Spacer()
                }
            }
            .navigationBarTitle("新增用餐紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    selectedFood = nil
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("取消")
                },
                trailing: Button(action: {
                    saveFoodRecord()
                }) {
                    Text("儲存")
                }
            )
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("儲存成功"),
                    message: Text("用餐紀錄已成功儲存"),
                    dismissButton: .default(Text("確定"))
                )
            }
            .onAppear {
                if let food = selectedFood {
                    name = food.name ?? ""
                    calories = food.calories
                }
            }
        }
    }
    
    private func saveFoodRecord() {
        guard !name.isEmpty, calories != nil else {
            return
        }
        
        let newFoodRecord = FoodRecord(context: viewContext)
        newFoodRecord.name = name
        newFoodRecord.calories = calories!
        newFoodRecord.calories *= Double(quantity)
        newFoodRecord.quantity = Int16(quantity)
        newFoodRecord.date = currentDate
        newFoodRecord.time = currentTime
        
        do {
            try viewContext.save()
            showAlert = true
            presentationMode.wrappedValue.dismiss()
            selectedFood = nil
        } catch {
            print("Error saving food record: \(error)")
        }
    }
    
    struct CardView: View {
        var food: FoodList
        
        var body: some View {
            VStack(alignment: .leading) {
                Text(food.name ?? "")
                    .foregroundColor(.white)
                    .padding([.leading,.top,.trailing])
                
                Text("\(String(format: "%.1f", food.calories ?? 0))大卡")
                    .foregroundColor(.white)
                    .padding([.leading,.bottom,.trailing])
            }
            .background(Color.black)
            .cornerRadius(10)
        }
    }
}

struct AddFoodView_Previews: PreviewProvider {
    static var previews: some View {
        AddFoodView(selectedFood: .constant(nil))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
