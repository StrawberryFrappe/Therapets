/// Pure, testable scan-result helpers.
///
/// Extracted from `BluetoothService`'s scan listener so the dedup/sort logic
/// can be unit-tested without constructing platform `ScanResult` objects.
/// Deliberately generic over the item type: production passes `ScanResult`,
/// tests pass plain records.
///
/// Note: there is intentionally NO name filtering here. Unnamed advertisements
/// used to be dropped, which hid devices from the scanner. They are now kept.
library;

/// Insert [item] into [list], or replace the existing entry with the same id.
///
/// Keyed by [idOf]. Update-in-place preserves the item's position so the UI
/// list does not reshuffle on every RSSI tick. Returns true when [list] changed
/// (always true here, but kept explicit for callers gating a redraw).
bool upsertById<T>(List<T> list, T item, String Function(T) idOf) {
  final id = idOf(item);
  final idx = list.indexWhere((e) => idOf(e) == id);
  if (idx == -1) {
    list.add(item);
  } else {
    list[idx] = item;
  }
  return true;
}

/// Stable-sort [list] so priority devices come first, order otherwise preserved.
void sortPriorityFirst<T>(List<T> list, bool Function(T) isPriority) {
  list.sort((a, b) {
    final pa = isPriority(a);
    final pb = isPriority(b);
    if (pa == pb) return 0;
    return pa ? -1 : 1;
  });
}
