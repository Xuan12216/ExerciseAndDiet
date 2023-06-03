//AddFoodView
import SwiftUI
import CoreData

struct AddFoodView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var calories: Double?
    @State private var quantity: Int = 1
    @State private var currentTime = Date()
    @State private var showAlert = false // 控制是否顯示Alert
    
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
                
                DatePicker("日期",selection: $currentTime)
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
    }
    private func saveFoodRecord() {
        let newFoodRecord = FoodRecord(context: viewContext)
        newFoodRecord.name = name
        newFoodRecord.calories = calories ?? 0
        newFoodRecord.calories *= Double(quantity)
        newFoodRecord.quantity = Int16(quantity)
        newFoodRecord.date = currentTime
        
        do {
            try viewContext.save()
            showAlert = true // 儲存成功後顯示Alert
            presentationMode.wrappedValue.dismiss() // 儲存成功後關閉視圖
        } catch {
            // 處理儲存錯誤
            print("Error saving food record: \(error)")
        }
    }
}

struct AddFoodView_Previews: PreviewProvider {
    static var previews: some View {
        AddFoodView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
