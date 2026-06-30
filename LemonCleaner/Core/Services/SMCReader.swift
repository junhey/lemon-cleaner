import Foundation

enum SMCReader {
    static func readTemperature() -> Double? {
        readViaPowermetrics()
    }

    static func readFanSpeed() -> Int? {
        nil
    }

    private static func readViaPowermetrics() -> Double? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/powermetrics")
        process.arguments = ["--samplers", "smc", "-n", "1", "-i", "100"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else { return nil }
            for line in output.components(separatedBy: "\n") {
                let lower = line.lowercased()
                if lower.contains("die temperature") || lower.contains("cpu temperature") {
                    let numbers = line.components(separatedBy: CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ: "))
                        .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                    if let temp = numbers.first, temp > 0, temp < 150 {
                        return temp
                    }
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
