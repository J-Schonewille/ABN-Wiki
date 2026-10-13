/// If `condition` never becomes true, the suite's time limit cancels the wait and the `#expect` after it fails.
@MainActor
func waitUntil(_ condition: () -> Bool) async {
    while !condition(), !Task.isCancelled {
        await Task.yield()
    }
}
