//StartView
import SwiftUI

struct StartView: View {
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var bmi: Double = 0.0
    @State private var suggestedCalories: Double = 0.0
    @State private var isShowingResult: Bool = false
    @State private var isNavPush = false
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(isActive: $isNavPush) {
                    MainView()
                        .navigationBarBackButtonHidden(true)
                } label: {}
                
                Spacer()
                TextField("請輸入體重 (公斤)", text: $weight)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 15)
                
                TextField("請輸入身高 (公分)", text: $height)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 15)
                
                Text("BMI: \(String(format: "%.1f", bmi))")
                    .font(.system(size: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 15)
                
                Text("建議攝取熱量: \(String(format: "%.1f", suggestedCalories)) 大卡")
                    .font(.system(size: 18))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 15)
                
                HStack {
                    if isShowingResult {
                        Button(action: {
                            // 重置輸入
                            weight = ""
                            height = ""
                            bmi = 0.0
                            suggestedCalories = 0
                            isShowingResult = false
                        }) {
                            Text("重新輸入")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 15)
                        
                        Button(action: {
                            let weightValue = Double(weight)
                            let heightValue = Double(height)
                            UserDefaults.standard.set(weightValue, forKey: "weight")
                            UserDefaults.standard.set(heightValue, forKey: "height")
                            UserDefaults.standard.set(bmi, forKey: "bmi")
                            UserDefaults.standard.set(suggestedCalories, forKey: "suggestedCalories")
                            isNavPush = true // 設置狀態為true，啟動頁面跳轉
                        }) {
                            Image(systemName: "arrow.right.circle.fill")
                                .resizable()
                                .frame(width: 50.0, height: 50.0)
                                .foregroundColor(.black)
                        }
                        .padding(.bottom, 15)
                        
                    } else {
                        Button(action: {
                            calculateBMI()
                            if (bmi != 0) {
                                isShowingResult = true
                            }
                        }) {
                            Text("計算BMI")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black)
                                .cornerRadius(10)
                        }
                        .padding(.bottom, 15)
                    }
                }
            }
            .navigationTitle("輸入身高與體重")
            .padding()
        }
    }
    
    private func calculateBMI() {
        guard let weightValue = Double(weight), weightValue > 0,
              let heightValue = Double(height), heightValue > 0 else {
            return // 如果沒有輸入有效的身高和體重，或是輸入了0，則直接返回
        }
        
        let heightInMeter = heightValue / 100
        bmi = weightValue / (heightInMeter * heightInMeter)
        calculateCalories()
    }
    
    private func calculateCalories() {
        // 根據BMI計算建議攝取熱量（大卡）
        let caloriesPerBMIUnit = 1250
        suggestedCalories = Double(bmi * Double(caloriesPerBMIUnit) / 10)
    }
}

struct StartView_Previews: PreviewProvider {
    static var previews: some View {
        StartView()
    }
}

//StartView
