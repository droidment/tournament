import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => [];
}

class TeamCreateRequested extends TeamEvent {

  const TeamCreateRequested({
    required this.tournamentId,
    required this.name,
    this.description,
    this.categoryId,
    this.contactEmail,
    this.contactPhone,
    this.seed,
    this.color,
  });
  final String tournamentId;
  final String name;
  final String? description;
  final String? categoryId;
  final String? contactEmail;
  final String? contactPhone;
  final int? seed;
  final Color? color;

  @override
  List<Object?> get props => [
        tournamentId,
        name,
        description,
        categoryId,
        contactEmail,
        contactPhone,
        seed,
        color,
      ];
}

class TournamentTeamsLoadRequested extends TeamEvent {

  const TournamentTeamsLoadRequested(this.tournamentId);
  final String tournamentId;

  @override
  List<Object?> get props => [tournamentId];
}

class CategoryTeamsLoadRequested extends TeamEvent {

  const CategoryTeamsLoadRequested(this.categoryId);
  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class TeamUpdateRequested extends TeamEvent {

  const TeamUpdateRequested({
    required this.teamId,
    this.name,
    this.description,
    this.categoryId,
    this.contactEmail,
    this.contactPhone,
    this.seed,
    this.color,
    this.isActive,
  });
  final String teamId;
  final String? name;
  final String? description;
  final String? categoryId;
  final String? contactEmail;
  final String? contactPhone;
  final int? seed;
  final Color? color;
  final bool? isActive;

  @override
  List<Object?> get props => [
        teamId,
        name,
        description,
        categoryId,
        contactEmail,
        contactPhone,
        seed,
        color,
        isActive,
      ];
}

class TeamDeleteRequested extends TeamEvent {

  const TeamDeleteRequested(this.teamId);
  final String teamId;

  @override
  List<Object?> get props => [teamId];
}

class UserTeamsLoadRequested extends TeamEvent {

  const UserTeamsLoadRequested(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
} 