import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var motionManager = MotionManager()
    @State private var isFilePickerPresented = false
    @State private var fileContent: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            HStack(spacing: 20) {
                Button(action: {
                    motionManager.toggleMotionUpdates()
                }) {
                    Text(motionManager.isMeasuring ? "Stop" : "Start")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(motionManager.isMeasuring ? Color.red : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: {
                    motionManager.resetMeasurements()
                }) {
                    Text("Reset")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Button(action: {
                    motionManager.stopMotionUpdates()
                    fileContent = motionManager.generateCSV()
                    isFilePickerPresented = true
                }) {
                    Text("Save")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            if !motionManager.accelerationData.isEmpty {
                LineGraph(data: motionManager.accelerationData)
                    .frame(height: 200)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .fileExporter(isPresented: $isFilePickerPresented, document: CSVDocument(text: fileContent), contentType: .plainText, defaultFilename: "accelerationData") { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print("Failed to save: \(error.localizedDescription)")
            }
        }
    }
}

struct LineGraph: View {
    var data: [(time: Date, value: Double)]

    var body: some View {
        GeometryReader { geometry in
            let path = createPath(in: geometry.size)
            path
                .stroke(Color.blue, lineWidth: 2)
            
            // Ajouter les labels pour l'axe temporel
            let xAxisLabels = createXAxisLabels(in: geometry.size)
            ForEach(xAxisLabels, id: \.0) { label in
                Text(label.1)
                    .font(.caption)
                    .position(x: label.0, y: geometry.size.height - 10)
            }
            
            // Ajouter les labels pour l'axe d'amplitude
            let yAxisLabels = createYAxisLabels(in: geometry.size)
            ForEach(yAxisLabels, id: \.0) { label in
                Text(label.1)
                    .font(.caption)
                    .position(x: 20, y: label.0)
            }
        }
    }

    private func createPath(in size: CGSize) -> Path {
        var path = Path()
        guard data.count > 1 else { return path }

        let startTime = data.first!.time
        let endTime = data.last!.time
        _ = endTime.timeIntervalSince(startTime) // Remplacer l'initialisation inutile

        let stepX = size.width / CGFloat(data.count - 1)
        let minY = data.min(by: { $0.value < $1.value })?.value ?? 0
        let maxY = data.max(by: { $0.value < $1.value })?.value ?? 0
        let rangeY = maxY - minY

        for (index, point) in data.enumerated() {
            let x = CGFloat(index) * stepX
            let y = size.height - ((CGFloat(point.value - minY) / CGFloat(rangeY)) * size.height)
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        return path
    }

    private func createXAxisLabels(in size: CGSize) -> [(CGFloat, String)] {
        guard let first = data.first else { return [] }

        var labels: [(CGFloat, String)] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "ss"
        
        // Espacer les labels de 5 secondes
        let timeInterval: TimeInterval = 5
        let startTime = first.time

        for point in data {
            let timeSinceStart = point.time.timeIntervalSince(startTime)
            if timeSinceStart.truncatingRemainder(dividingBy: timeInterval) == 0 {
                let x = CGFloat(timeSinceStart) / CGFloat(data.last!.time.timeIntervalSince(startTime)) * size.width
                let label = dateFormatter.string(from: point.time)
                labels.append((x, label))
            }
        }

        return labels
    }


    private func createYAxisLabels(in size: CGSize) -> [(CGFloat, String)] {
        guard let minY = data.min(by: { $0.value < $1.value })?.value,
              let maxY = data.max(by: { $0.value < $1.value })?.value else { return [] }

        var labels: [(CGFloat, String)] = []

        let rangeY = maxY - minY
        let stepY = rangeY / 5 // Divise l'axe Y en 5 segments

        for i in 0...5 {
            let value = minY + (stepY * Double(i))
            let y = size.height - ((CGFloat(value - minY) / CGFloat(rangeY)) * size.height)
            labels.append((y, String(format: "%.2f", value)))
        }

        return labels
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    
    var text: String
    
    init(text: String = "") {
        self.text = text
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents, let content = String(data: data, encoding: .utf8) {
            text = content
        } else {
            text = ""
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

#Preview {
    ContentView()
}
