enum SortOrder {
  nameAsc('name_asc'),
  nameDesc('name_desc'),
  sizeAsc('size_asc'),
  sizeDesc('size_desc'),
  dateAsc('date_asc'),
  dateDesc('date_desc');

  final String value;
  const SortOrder(this.value);

  /// Optional: Helper to find an enum from a raw string value
  static SortOrder? fromValue(String value) {
    return SortOrder.values.cast<SortOrder?>().firstWhere(
          (element) => element?.value == value,
          orElse: () => null,
        );
  }
}