/// The state of [Bus], where [Pending] means that the bus has never been
/// initialized, [Initialized] means that the bus is ready for use, and
/// [Destroyed] means that the bus has released all of its resources and
/// can no longer be used.
enum BusState {
  Pending,
  Initialized,
  Destroyed,
}
