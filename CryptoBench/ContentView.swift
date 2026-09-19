import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var engine = BenchmarkEngine()

    var body: some View {
        NavigationStack {
            Form {
                Section("Device") {
                    LabeledContent("Device", value: UIDevice.current.model)
                    LabeledContent("iOS", value: UIDevice.current.systemVersion)
                    LabeledContent("Thermal", value: engine.thermal)
                }
                Section("CPU Benchmark") {
                    Stepper("Threads: \(engine.threads)", value: $engine.threads, in: 1...6)
                        .disabled(engine.running)
                    LabeledContent("Throughput", value: String(format: "%.2f M ops/s", engine.score))
                    LabeledContent("Elapsed", value: String(format: "%.0f sec", engine.elapsed))
                    Button(engine.running ? "Stop Benchmark" : "Start Benchmark") {
                        engine.running ? engine.stop() : engine.start()
                    }
                }
                Section {
                    Text("Phase 1 measures CPU performance and thermal behaviour only. It does not mine cryptocurrency or connect to a pool.")
                        .font(.footnote)
                }
            }
            .navigationTitle("Crypto Bench")
        }
    }
}
