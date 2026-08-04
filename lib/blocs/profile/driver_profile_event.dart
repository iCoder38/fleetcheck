part of 'driver_profile_bloc.dart';

sealed class DriverProfileEvent {}

final class ProfileLoadRequested extends DriverProfileEvent {}

final class ProfileUpdateRequested extends DriverProfileEvent {
  final String? phone;
  final String? email;
  ProfileUpdateRequested({this.phone, this.email});
}
final class ProfilePhotoUpdateRequested extends DriverProfileEvent {
  final File? photoFile;
  ProfilePhotoUpdateRequested({this.photoFile});
}

final class PasswordChangeRequested extends DriverProfileEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;
  PasswordChangeRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}
