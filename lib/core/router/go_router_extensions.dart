import 'package:go_router/go_router.dart';

extension GoRouterLocation on GoRouter {
  /// The location of the route the user is actually looking at.
  ///
  /// `routerDelegate.currentConfiguration.uri` can't be used directly:
  /// `context.push()` adds an imperative match, and the match list's own `uri`
  /// still reports the base location (e.g. `/home` while a pushed `/login` is
  /// on screen). Unwrapping the topmost match — for an imperative push that's
  /// its inner match list — yields the real current route.
  String get location {
    final matchList = routerDelegate.currentConfiguration;
    final lastMatch = matchList.last;
    return (lastMatch is ImperativeRouteMatch ? lastMatch.matches : matchList)
        .uri
        .toString();
  }
}
