// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Abhiraj.

import SwiftUI

@main
struct AgentAtomDemoApp: App {
    @State private var model = DemoViewModel()

    var body: some Scene {
        WindowGroup {
            DemoView(model: model)
                .frame(minWidth: 620, minHeight: 600)
        }
    }
}

struct DemoView: View {
    @Bindable var model: DemoViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("AgentAtom Demo").font(.largeTitle.bold())
                Text("Extract three facts and named people using the local Apple model.")
                    .foregroundStyle(.secondary)
                Text("Input").font(.headline)
                TextEditor(text: $model.input)
                    .font(.body)
                    .frame(height: 140)
                    .border(.secondary.opacity(0.3))
                    .disabled(model.isRunning)
                    .accessibilityLabel("Input text")
                HStack {
                    Button("Generate") { Task { await model.run() } }
                        .keyboardShortcut(.return, modifiers: .command)
                        .disabled(model.isRunning || model.input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Button("Cancel") { Task { await model.cancel() } }
                        .disabled(!model.isRunning)
                    if model.isRunning { ProgressView().controlSize(.small) }
                }
                Text(model.status).textSelection(.enabled)
                if let output = model.output {
                    Text("Key points").font(.headline)
                    ForEach(Array(output.points.enumerated()), id: \.offset) { _, point in
                        Text("• \(point)").textSelection(.enabled)
                    }
                    Text("People: " + (output.people.isEmpty ? "None named" : output.people.joined(separator: ", ")))
                        .textSelection(.enabled)
                }
                DisclosureGroup("Raw JSON (snapshots may be incomplete)") {
                    Text(model.rawJSON.isEmpty ? "No response yet." : model.rawJSON)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }.padding(24)
        }
    }
}
