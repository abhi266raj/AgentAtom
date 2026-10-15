// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Abhiraj.

public protocol Spec: Sendable {
    static var identity: Identity { get }

    var inputJSON: JSONString { get }
    static var outputSchema: JSONSchema { get }
    static var role: String { get }
    var instructions: String { get }
}
