// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Abhiraj.

import AgentAtom

struct DemoOutput: Decodable, Sendable {
    let points: [String]
    let people: [String]
}

struct DemoSpec: ModelledSpec {
    static let identity = Identity(id: "demo-key-points", name: "Key Points", version: "1")
    static let role = "Extract factual key points and explicitly named people."
    let instructions = """
        Return exactly three distinct facts explicitly supported by the input.
        If fewer than three facts are supplied, choose Failure instead of inventing facts.
        List distinct explicitly named people in first-appearance order; use an empty
        people array if no people are named. Write short, clear sentences.
        """
    let input: String
    var output: DemoOutput?
}
