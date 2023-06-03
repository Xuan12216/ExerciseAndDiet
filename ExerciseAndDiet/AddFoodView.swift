import SwiftUI
import CoreData

struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @Binding var selectedFood: FoodList? // 添加selectedFood属性
    
    @State private var name: String = ""
    @State private var calories: Double?
    @State private var quantity: Int = 1
    @State private var currentDate = Date()
    @State private var currentTime = Date()
    @State private var showAlert = false // 控制是否顯示Alert，成功儲存
    
    var maximumDate: Date {
        return Calendar.current.startOfDay(for: Date())
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Text("名稱")
                        .padding([.top, .leading, .bottom])
                    
                    TextField("輸入食物名稱", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding([.top, .trailing, .bottom])
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
            showAlert = true // 儲存成功後顯示Alert
            presentationMode.wrappedValue.dismiss() // 儲存成功後關閉視圖
            selectedFood = nil // 清空selectedFood的值
        } catch {
            // 處理儲存錯誤
            print("Error saving food record: \(error)")
        }
    }
}

struct AddFoodView_Previews: PreviewProvider {
    static var previews: some View {
        AddFoodView(selectedFood: .constant(nil))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
