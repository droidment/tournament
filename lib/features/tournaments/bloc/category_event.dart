import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class CategoryCreateRequested extends CategoryEvent {
  final String tournamentId;
  final String name;
  final String? description;
  final int? maxTeams;
  final int minTeams;
  final int displayOrder;

  const CategoryCreateRequested({
    required this.tournamentId,
    required this.name,
    this.description,
    this.maxTeams,
    this.minTeams = 2,
    this.displayOrder = 0,
  });

  @override
  List<Object?> get props => [
        tournamentId,
        name,
        description,
        maxTeams,
        minTeams,
        displayOrder,
      ];
}

class TournamentCategoriesLoadRequested extends CategoryEvent {
  final String tournamentId;

  const TournamentCategoriesLoadRequested(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
}

class CategoryUpdateRequested extends CategoryEvent {
  final String categoryId;
  final String? name;
  final String? description;
  final int? maxTeams;
  final int? minTeams;
  final bool? isActive;
  final int? displayOrder;

  const CategoryUpdateRequested({
    required this.categoryId,
    this.name,
    this.description,
    this.maxTeams,
    this.minTeams,
    this.isActive,
    this.displayOrder,
  });

  @override
  List<Object?> get props => [
        categoryId,
        name,
        description,
        maxTeams,
        minTeams,
        isActive,
        displayOrder,
      ];
}

class CategoryDeleteRequested extends CategoryEvent {
  final String categoryId;

  const CategoryDeleteRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class CategoriesReorderRequested extends CategoryEvent {
  final List<Map<String, dynamic>> categoryOrders;

  const CategoriesReorderRequested(this.categoryOrders);

  @override
  List<Object?> get props => [categoryOrders];
}

class DefaultCategoriesCreateRequested extends CategoryEvent {
  final String tournamentId;

  const DefaultCategoriesCreateRequested(this.tournamentId);

  @override
  List<Object?> get props => [tournamentId];
} 