part of 'driver_profile_bloc.dart';

/// Profile load, profile update, and password change are three independent
/// concerns on the same screen (the latter two via modal bottom sheets), so
/// this state holds separate flag/error fields for each rather than a single
/// sealed hierarchy.
class DriverProfileState {
  final DriverModel? driver;

  final bool isUpdatingProfile;
  final String? updateError;
  final bool profileUpdateSucceeded;

  final bool isChangingPassword;
  final String? passwordError;
  final bool passwordChangeSucceeded;

  const DriverProfileState({
    this.driver,
    this.isUpdatingProfile = false,
    this.updateError,
    this.profileUpdateSucceeded = false,
    this.isChangingPassword = false,
    this.passwordError,
    this.passwordChangeSucceeded = false,
  });
}
