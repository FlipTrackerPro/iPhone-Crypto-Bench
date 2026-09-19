import Foundation
import Combine

@MainActor
final class BenchmarkEngine: ObservableObject {
    @Published var running = false
    @Published var threads = 2
    @Published var score = 0.0
    @Published var elapsed = 0.0
    @Published var thermal = "Unknown"

    private var workers: [Task<Void, Never>] = []
    private var timer: Timer?
    private var startTime = Date()
    private var operations: UInt64 = 0

    func start() {
        guard !running else { return }
        running = true
        score = 0
        operations = 0
        startTime = Date()
        updateThermal()

        for _ in 0..<threads {
            workers.append(Task.detached(priority: .userInitiated) { [weak self] in
                var x: UInt64 = 0x9e3779b97f4a7c15
                while !Task.isCancelled {
                    for _ in 0..<250_000 {
                        x ^= x >> 12
                        x ^= x << 25
                        x ^= x >> 27
                        x &*= 2685821657736338717
                    }
                    await self?.add(250_000)
                }
                _ = x
            })
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func add(_ value: UInt64) { operations &+= value }

    private func tick() {
        elapsed = Date().timeIntervalSince(startTime)
        if elapsed > 0 { score = Double(operations) / elapsed / 1_000_000 }
        updateThermal()
        if ProcessInfo.processInfo.thermalState == .critical { stop() }
    }

    func stop() {
        workers.forEach { $0.cancel() }
        workers.removeAll()
        timer?.invalidate()
        timer = nil
        running = false
    }

    private func updateThermal() {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = "Nominal"
        case .fair: thermal = "Fair"
        case .serious: thermal = "Serious"
        case .critical: thermal = "Critical"
        @unknown default: thermal = "Unknown"
        }
    }
}
