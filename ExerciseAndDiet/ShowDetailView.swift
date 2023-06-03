import SwiftUI
import CoreData

struct ShowDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \FoodRecord.date, ascending: false)],
        animation: .default)
    private var foodRecords: FetchedResults<FoodRecord>
    
    struct GroupedFoodRecord: Hashable {
        let date: Date
        let foodRecords: [FoodRecord]
    }
    
    private var groupedFoodRecords: [GroupedFoodRecord] {
        Dictionary(grouping: foodRecords) { foodRecord in
            Calendar.current.startOfDay(for: foodRecord.date!)
        }
        .map { date, foodRecords in
            GroupedFoodRecord(date: date, foodRecords: foodRecords)
        }
        .sorted { $0.date > $1.date }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(groupedFoodRecords, id: \.self) { group in
                    Section(header: Text(formattedDate(group.date))) {
                        ForEach(group.foodRecords) { foodRecord in
                            VStack(alignment: .leading) {
                                Text(foodRecord.name ?? "")
                                    .font(.headline)
                                Text("熱量: \(String(format: "%.1f", foodRecord.calories)) 大卡")
                                    .font(.subheadline)
                                Text("數量: \(foodRecord.quantity)")
                                    .font(.subheadline)
                                if let time = foodRecord.time {
                                    Text("時間: \(formattedTime(time))")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("用餐紀錄")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("返回")
                }
            )
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formattedTime(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: time)
    }
}

struct ShowDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ShowDetailView()
    }
}
