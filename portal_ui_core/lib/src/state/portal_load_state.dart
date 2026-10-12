/// The fleet's four states for an async page (G1): a load is always exactly
/// one of these, never inferred by checking several nullable fields at once.
enum PortalLoadState {
  loading,
  empty,
  error,
  data,
}
