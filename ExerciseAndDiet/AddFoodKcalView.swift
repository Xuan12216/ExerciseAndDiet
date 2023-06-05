import SwiftUI

struct AddFoodKcalView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var name: String = ""
    @State private var calories: Double?
    @State private var showAlert = false // 控制是否顯示Alert，成功儲存
    @State private var isRepeatAlert = false // 控制是否顯示Alert，重複名稱
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodList.name, ascending: true)],
        animation: .default)
    private var foodList: FetchedResults<FoodList>
    
    var body: some View {
        NavigationView{
            VStack{
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
                Spacer()
            }
        }
        .navigationBarTitle("新建食物")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            leading: Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("取消")
            },
            trailing: Button(action: {
                addFoodKcal()
            }) {
                Text("儲存")
            }
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("儲存成功"),
                message: Text("食物資料已成功儲存"),
                dismissButton: .default(Text("確定"))
            )
        }
        .alert(isPresented: $isRepeatAlert) {
            Alert(
                title: Text("名稱重複"),
                message: Text("請重新輸入不同名稱"),
                dismissButton: .default(Text("確定"))
            )
        }
    }
    
    private func addFoodKcal() {
        guard !name.isEmpty, calories != nil else {
            return
        }
        
        let existingFood = foodList.first { $0.name == name }
        
        if existingFood != nil {
            // 名稱已存在，顯示錯誤提示
            isRepeatAlert = true
            return
        }
        
        let newFood = FoodList(context: viewContext)
        newFood.name = name
        newFood.calories = calories!
        
        do {
            try viewContext.save()
            showAlert = true // 儲存成功後顯示Alert
            NotificationCenter.default.post(name: Notification.Name("FoodListAdded"), object: nil) // 发送通知
            presentationMode.wrappedValue.dismiss() // 儲存成功後關閉視圖
        } catch {
            // 處理儲存錯誤
            print("Error saving food record: \(error)")
        }
    }
}

struct AddFoodKcalView_Previews: PreviewProvider {
    static var previews: some View {
        AddFoodKcalView()
    }
}
