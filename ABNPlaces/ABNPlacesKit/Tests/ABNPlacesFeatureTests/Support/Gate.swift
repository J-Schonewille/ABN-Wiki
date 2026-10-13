import ABNPlacesCore
import Synchronization
import Testing

/// A stand-in for a slow dependency: its caller waits in `wait()` until the test calls `open(with:)`.
/// It lets a test act while a request is in flight, in a fixed order and without sleeping:
/// 1. Start the work. Its dependency calls `wait()` and waits there.
/// 2. `await waitForArrival()`: the request is now in flight.
/// 3. Act, then `open(with:)` to let the request finish.
/// - **One caller.** A second caller while the first waits is what a broken loading or double-tap guard looks like, so
///   it records an issue and gets `whenCancelled` straight away. The test then fails there, not at its time limit.
/// - **Cancelling ends both waits,** like it ends a real request. A test that runs out of time then stops and says
///   which check failed, instead of hanging.
final class Gate<Value: Sendable>: Sendable {
    private struct State {
        var value: Value?
        var hasArrival = false
        var nextID = 0
        var waiter: (id: Int, continuation: CheckedContinuation<Value, Never>)?
        var arrivalWatcher: CheckedContinuation<Void, Never>?
    }

    private let state = Mutex(State())
    private let whenCancelled: Value

    /// - Parameter whenCancelled: What `wait()` returns when it can't wait: its task is cancelled, or another caller
    ///   is already waiting. Pass what the real dependency answers a cancelled caller.
    init(whenCancelled: Value) {
        self.whenCancelled = whenCancelled
    }

    /// Called by the stand-in dependency: waits until the gate opens, then returns its value.
    func wait() async -> Value {
        let id = state.withLock { state in
            state.nextID += 1
            return state.nextID
        }
        return await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let (answer, isSecondCaller, watcher) = state.withLock { state in
                    state.hasArrival = true
                    // A task is marked cancelled before its cancel handler runs, and both take the lock, so a caller
                    // cancelled before it got here sees it.
                    var answer = state.value ?? (Task.isCancelled ? whenCancelled : nil)
                    let isSecondCaller = answer == nil && state.waiter != nil
                    if isSecondCaller {
                        answer = whenCancelled
                    } else if answer == nil {
                        state.waiter = (id, continuation)
                    }
                    return (answer, isSecondCaller, state.arrivalWatcher.take())
                }
                watcher?.resume()
                if isSecondCaller {
                    Issue.record("A second caller reached the gate while the first was still waiting")
                }
                if let answer {
                    continuation.resume(returning: answer)
                }
            }
        } onCancel: {
            let waiter = state.withLock { state in
                state.waiter?.id == id ? state.waiter.take() : nil
            }
            waiter?.continuation.resume(returning: whenCancelled)
        }
    }

    /// Waits until the caller has reached the gate, or until this task is cancelled.
    func waitForArrival() async {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                let hasArrived = state.withLock { state in
                    guard !state.hasArrival, !Task.isCancelled else { return true }
                    state.arrivalWatcher = continuation
                    return false
                }
                if hasArrived {
                    continuation.resume()
                }
            }
        } onCancel: {
            state.withLock { $0.arrivalWatcher.take() }?.resume()
        }
    }

    /// Lets the waiting caller through with `value`, and any caller that arrives later.
    func open(with value: Value) {
        let waiter = state.withLock { state in
            state.value = value
            return state.waiter.take()
        }
        waiter?.continuation.resume(returning: value)
    }
}

extension Gate where Value == FetchResult {
    /// A gate for a fetch: a cancelled caller gets `.cancelled`, like from the live client.
    convenience init() {
        self.init(whenCancelled: .failure(.cancelled))
    }
}

extension Gate where Value == Bool {
    /// A gate for `openURL`: a cancelled caller gets `false`, like from the real `OpenURLEffect`.
    convenience init() {
        self.init(whenCancelled: false)
    }
}
