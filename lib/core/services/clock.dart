/// Core interface for time-based operations.
/// 
/// 🕒 **Technical Rationale**: Injecting a clock instead of using [DateTime.now]
/// allows for deterministic unit testing and prevents "flaky" time-dependent tests.
abstract class IClock {
  DateTime now();
}

/// Production implementation of [IClock] using system time.
class SystemClock implements IClock {
  @override
  DateTime now() => DateTime.now();
}
