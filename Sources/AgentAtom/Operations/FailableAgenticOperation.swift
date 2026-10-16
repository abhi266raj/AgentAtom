// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Abhiraj.

public actor FailableAgenticOperation<Specification: Spec, Session: AgenticSessionProtocol>: AgenticOperationProtocol, OperationLifecycle {
    public typealias Result = Swift.Result<String, AgenticError>

    public let spec: Specification
    public internal(set) var state: OperationState = .ready
    let session: Session
    let strategy = FailableOperationStrategy()
    var task: Task<Swift.Result<String, AgenticError>, Never>?

    public init(spec: Specification, session: Session) {
        self.spec = spec
        self.session = session
    }

    public func instructions() throws(AgenticError) -> String { try lifecycleInstructions() }
    public func cancel() { cancelRun() }
    public func pause() async throws(AgenticError) { try await pauseRun() }
    public func resume() async throws(AgenticError) { try await resumeRun() }

    public func execute() async -> Result {
        await start()
    }
}
