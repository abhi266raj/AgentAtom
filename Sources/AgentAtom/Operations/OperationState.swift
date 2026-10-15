// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Abhiraj.

public enum OperationState: Sendable {
    case ready, running, paused, cancelling, completed, cancelled, failed

    var canStart: Bool {
        switch self {
        case .ready, .completed, .cancelled, .failed: true
        case .running, .paused, .cancelling: false
        }
    }
}
