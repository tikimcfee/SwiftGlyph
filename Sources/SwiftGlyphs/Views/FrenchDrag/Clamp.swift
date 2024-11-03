func clamp<T: Comparable>(_ value: T, min minIn: T, max maxIn: T) -> T {
    max(min(maxIn, value), minIn)
}
