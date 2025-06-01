import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  final String userId;

  const ProfileLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {
  final String userId;
  final String? fullName;
  final String? bio;
  final String? phone;
  final String? location;
  final DateTime? dateOfBirth;

  const ProfileUpdateRequested({
    required this.userId,
    this.fullName,
    this.bio,
    this.phone,
    this.location,
    this.dateOfBirth,
  });

  @override
  List<Object?> get props => [
        userId,
        fullName,
        bio,
        phone,
        location,
        dateOfBirth,
      ];
}

class ProfilePictureUploadRequested extends ProfileEvent {
  final String userId;
  final File imageFile;

  const ProfilePictureUploadRequested({
    required this.userId,
    required this.imageFile,
  });

  @override
  List<Object?> get props => [userId, imageFile];
}

class ProfilePictureDeleteRequested extends ProfileEvent {
  final String userId;

  const ProfilePictureDeleteRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class MyTournamentsLoadRequested extends ProfileEvent {
  final String userId;

  const MyTournamentsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class ProfileRefreshRequested extends ProfileEvent {
  final String userId;

  const ProfileRefreshRequested(this.userId);

  @override
  List<Object?> get props => [userId];
} 