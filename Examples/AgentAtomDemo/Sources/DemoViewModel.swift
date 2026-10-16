// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Abhiraj.

import AgentAtom
import Foundation
import Observation

@Observable @MainActor
final class DemoViewModel {
    var input = "Asha opened the library on Monday. Ben donated twenty books. Asha hosted a reading session on Friday."
    private(set) var isRunning = false
    private(set) var status = "Ready. Requires Apple Intelligence to be enabled and available."
    private(set) var rawJSON = ""
    private(set) var output: DemoOutput?
    private var active: FailableStreamingAgenticOperation<DemoSpec, AppleIntelligenceSession>?

    func run() async {
        guard !isRunning else { return }
        output = nil
        rawJSON = ""
        guard let session = AppleIntelligenceSession() else {
            status = "Apple Intelligence is unavailable. Check device support, enable Apple Intelligence in System Settings, and allow model downloads to finish."
            return
        }
        isRunning = true
        status = "Generating…"
        let operation = FailableStreamingAgenticOperation(spec: DemoSpec(input: input), session: session)
        active = operation
        defer { active = nil; isRunning = false }
        var failure: AgenticError?
        for await result in await operation.execute() {
            switch result {
            case .success(let text): rawJSON = text
            case .failure(let error): failure = error
            }
        }
        if let failure {
            switch failure {
            case .generationFailed(let reason):
                status = "AI-declared failure: " + Self.failureReason(reason)
            case .operationFailed(let reason):
                status = "Provider or operation error: " + Self.failureReason(reason)
            default:
                status = failure.localizedDescription
            }
            return
        }
        do {
            let decoded = try JSONDecoder().decode(DemoOutput.self, from: Data(rawJSON.utf8))
            guard decoded.points.count == 3 else {
                status = "The response did not contain exactly three points. The caller must validate domain requirements."
                return
            }
            output = decoded
            status = "Completed. Final JSON decoded and three-point requirement validated."
        } catch {
            status = "Could not decode the final response: \(error.localizedDescription)"
        }
    }

    private static func failureReason(_ reason: String) -> String {
        let text = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let generic = text.lowercased().trimmingCharacters(in: .punctuationCharacters)
        if text.isEmpty || ["rejected", "failed", "failure", "invalid input"].contains(generic) {
            return (text.isEmpty ? "No reason supplied." : text) +
                " The provider did not supply a more specific reason. This sample requires three distinct facts; check the input against that requirement."
        }
        return text
    }

    func cancel() async {
        guard let active else { return }
        status = "Cancelling…"
        await active.cancel()
    }
}
