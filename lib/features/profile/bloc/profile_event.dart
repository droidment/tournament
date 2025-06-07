import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {

  const ProfileLoadRequested(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ProfileUpdateRequested extends ProfileEvent {

  const ProfileUpdateRequested({
    required this.userId,
    this.fullName,
    this.bio,
    this.phone,
    this.location,
    this.dateOfBirth,
  });
  final String userId;
  final String? fullName;
  final String? bio;
  final String? phone;
  final String? location;
  final DateTime? dateOfBirth;

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

  const ProfilePictureUploadRequested({
    required this.userId,
    required this.imageFile,
  });
  final String userId;
  final File imageFile;

  @override
  List<Object?> get props => [userId, imageFile];
}

class ProfilePictureDeleteRequested extends ProfileEvent {

  const ProfilePictureDeleteRequested(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class MyTournamentsLoadRequested extends ProfileEvent {

  const MyTournamentsLoadRequested(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class ProfileRefreshRequested extends ProfileEvent {

  const ProfileRefreshRequested(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
} 