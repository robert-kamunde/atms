import '../../features/auth/domain/auth_state.dart';
import '../../shared/models/user_role.dart';
import 'route_names.dart';

/// Routes a signed-out user may open.
const Set<String> _signInPaths = {
  RoutePaths.signInPhone,
  RoutePaths.signInCode,
  RoutePaths.signInEmail,
};

/// Routes that only make sense before the user is fully signed in. A
/// signed-in user who opens one is sent to their task list.
const Set<String> _preSignInPaths = {
  RoutePaths.loading,
  RoutePaths.setupMissing,
  RoutePaths.signInPhone,
  RoutePaths.signInCode,
  RoutePaths.signInEmail,
  RoutePaths.notInvited,
  RoutePaths.onboardingLanguage,
  RoutePaths.onboardingConsent,
  RoutePaths.onboardingNotifications,
};

/// Routes for managers and admins only.
const Set<String> _teamPaths = {RoutePaths.teamTasks, RoutePaths.reports};

bool _isUnder(String path, String prefix) =>
    path == prefix || path.startsWith('$prefix/');

/// True for the admin area (`/admin/...`), which also needs the admin
/// second factor.
bool isAdminPath(String path) => _isUnder(path, RoutePaths.adminPrefix);

/// Can [role] open [path]? (Role-based part of the guard.)
///
/// This only hides screens. Real enforcement is in Firestore Security Rules
/// and Cloud Functions: the client is never trusted (spec 6).
bool canRoleOpen(UserRole role, String path) {
  if (isAdminPath(path) || path == RoutePaths.adminVerify) {
    return role == UserRole.admin;
  }
  if (_teamPaths.any((p) => _isUnder(path, p))) {
    return role.canSeeTeam;
  }
  return true;
}

/// Where the admin second-factor screen sends the admin afterwards: the
/// admin screen they wanted, or the More tab. Only admin paths are
/// accepted so the parameter cannot send them anywhere else.
String adminVerifyReturnPath(String? requested) =>
    requested != null && isAdminPath(Uri.parse(requested).path)
    ? requested
    : RoutePaths.more;

/// The redirect rule of the router: returns where [location] should go for
/// [auth] at [now], or null to stay.
///
/// Admins need a current `adminVerifiedUntil` claim (D-01) for `/admin/...`
/// screens; without it they are sent to the second-factor screen and keep
/// staff-level access to everything else (their own tasks).
String? guardRedirect(AuthState auth, Uri location, {DateTime? now}) {
  final path = location.path;

  String? goTo(String target) => path == target ? null : target;

  switch (auth) {
    case AuthUnknown():
      return goTo(RoutePaths.loading);
    case AuthNotConfigured():
      return goTo(RoutePaths.setupMissing);
    case AuthSignedOut():
      return _signInPaths.contains(path) ? null : RoutePaths.signInPhone;
    case AuthNotInvited():
      return goTo(RoutePaths.notInvited);
    case AuthNeedsLanguage():
      return goTo(RoutePaths.onboardingLanguage);
    case AuthNeedsConsent():
      return goTo(RoutePaths.onboardingConsent);
    case AuthNeedsNotificationPermission():
      return goTo(RoutePaths.onboardingNotifications);
    case AuthSignedIn(:final role):
      if (_preSignInPaths.contains(path) || path == '/') {
        return RoutePaths.tasks;
      }
      if (!canRoleOpen(role, path)) return RoutePaths.tasks;
      if (isAdminPath(path) && !auth.isAdminVerifiedAt(now ?? DateTime.now())) {
        return RoutePaths.adminVerifyFor(location.toString());
      }
      return null;
  }
}
