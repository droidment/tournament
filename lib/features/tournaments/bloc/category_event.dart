import 'package:equatable/equatable.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class CategoryCreateRequested extends CategoryEvent {

  const CategoryCreateRequested({
    required this.tournamentId,
    required this.name,
    this.description,
    this.maxTeams,
    this.minTeams = 2,
    this.displayOrder = 0,
  });
  final String tournamentId;
  final String name;
  final String? description;
  final int? maxTeams;
  final int minTeams;
  final int displayOrder;

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

  const TournamentCategoriesLoadRequested(this.tournamentId);
  final String tournamentId;

  @override
  List<Object?> get props => [tournamentId];
}

class CategoryUpdateRequested extends CategoryEvent {

  const CategoryUpdateRequested({
    required this.categoryId,
    this.name,
    this.description,
    this.maxTeams,
    this.minTeams,
    this.isActive,
    this.displayOrder,
  });
  final String categoryId;
  final String? name;
  final String? description;
  final int? maxTeams;
  final int? minTeams;
  final bool? isActive;
  final int? displayOrder;

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

  const CategoryDeleteRequested(this.categoryId);
  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

class CategoriesReorderRequested extends CategoryEvent {

  const CategoriesReorderRequested(this.categoryOrders);
  final List<Map<String, dynamic>> categoryOrders;

  @override
  List<Object?> get props => [categoryOrders];
}

class DefaultCategoriesCreateRequested extends CategoryEvent {

  const DefaultCategoriesCreateRequested(this.tournamentId);
  final String tournamentId;

  @override
  List<Object?> get props => [tournamentId];
} 