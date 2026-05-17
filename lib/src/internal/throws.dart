import 'package:meta/meta.dart';

/// Informs the function can throw errors depending on the context and usage. The origin
/// of the exception can come from within the function scope, or it can come from a
/// nested function - either passed to the functions arguments or by calling another
/// function elsewhere.
///
/// This exists to help notify the caller of any possible unknown outcomes. The details
/// and context of the errors that can be thrown should be provided in the function's
/// code docs. In the event of overwhelming documentation, or the author failed to
/// document possible outcomes, let this annotation be highlight to the function's
/// signature.
@internal
const throws = _Throws();

final class _Throws {

  const _Throws();
}