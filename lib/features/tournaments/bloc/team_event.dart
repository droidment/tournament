import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class TeamEvent extends Equatable {
  const TeamEvent();

  @override
  List<Object?> get props => [];
}

class TeamCreateRequested extends TeamEvent {
  final String tournamentId;
  final String name;
  final String? description;
  final String? categoryId;
  final String? contactEmail;
  final String? contactPhone;
  final int? seed;
  final Color? color;

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
  final String tournamentId;

  const TournamentTeamsLoadRequested(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class CategoryTeamsLoadRequested extends TeamEvent {
  final String categoryId;

  const CategoryTeamsLoadRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class TeamUpdateRequested extends TeamEvent {
  final String teamId;
  final String? name;
  final String? description;
  final String? categoryId;
  final String? contactEmail;
  final String? contactPhone;
  final int? seed;
  final Color? color;
  final bool? isActive;

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
  final String teamId;

  const TeamDeleteRequested(this.teamId);

  @override
  List<Object?> get props => [teamId];
}

class UserTeamsLoadRequested extends TeamEvent {
  final String userId;

  const UserTeamsLoadRequested(this.userId);

  @override
  List<Object?> get props => [userId];
} 