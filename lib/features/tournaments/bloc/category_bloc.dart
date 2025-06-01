import 'package:flutter_bloc/flutter_bloc.dart';
import 'category_event.dart';
import 'category_state.dart';
import '../data/repositories/category_repository.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryRepository _categoryRepository;

  CategoryBloc({CategoryRepository? categoryRepository})
      : _categoryRepository = categoryRepository ?? CategoryRepository(),
        super(const CategoryState()) {
    on<CategoryCreateRequested>(_onCategoryCreateRequested);
    on<TournamentCategoriesLoadRequested>(_onTournamentCategoriesLoadRequested);
    on<CategoryUpdateRequested>(_onCategoryUpdateRequested);
    on<CategoryDeleteRequested>(_onCategoryDeleteRequested);
    on<CategoriesReorderRequested>(_onCategoriesReorderRequested);
    on<DefaultCategoriesCreateRequested>(_onDefaultCategoriesCreateRequested);
  }

  Future<void> _onCategoryCreateRequested(
    CategoryCreateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.toCreating());

    try {
      final category = await _categoryRepository.createCategory(
        tournamentId: event.tournamentId,
        name: event.name,
        description: event.description,
        maxTeams: event.maxTeams,
        minTeams: event.minTeams,
        displayOrder: event.displayOrder,
      );

      // Load updated categories list
      final categories = await _categoryRepository.getTournamentCategories(event.tournamentId);
      emit(state.toSuccess(categories: categories, selectedCategory: category));
    } catch (e) {
      emit(state.toError('Failed to create category: ${e.toString()}'));
    }
  }

  Future<void> _onTournamentCategoriesLoadRequested(
    TournamentCategoriesLoadRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.toLoading());

    try {
      final categories = await _categoryRepository.getTournamentCategories(event.tournamentId);
      emit(state.toSuccess(categories: categories));
    } catch (e) {
      emit(state.toError('Failed to load categories: ${e.toString()}'));
    }
  }

  Future<void> _onCategoryUpdateRequested(
    CategoryUpdateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.toUpdating());

    try {
      final updatedCategory = await _categoryRepository.updateCategory(
        categoryId: event.categoryId,
        name: event.name,
        description: event.description,
        maxTeams: event.maxTeams,
        minTeams: event.minTeams,
        isActive: event.isActive,
        displayOrder: event.displayOrder,
      );

      // Update the categories list
      final updatedCategories = state.categories.map((category) {
        return category.id == event.categoryId ? updatedCategory : category;
      }).toList();

      emit(state.toSuccess(categories: updatedCategories, selectedCategory: updatedCategory));
    } catch (e) {
      emit(state.toError('Failed to update category: ${e.toString()}'));
    }
  }

  Future<void> _onCategoryDeleteRequested(
    CategoryDeleteRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.toDeleting());

    try {
      await _categoryRepository.deleteCategory(event.categoryId);

      // Remove the deleted category from the list
      final updatedCategories = state.categories
          .where((category) => category.id != event.categoryId)
          .toList();

      emit(state.toSuccess(categories: updatedCategories));
    } catch (e) {
      emit(state.toError('Failed to delete category: ${e.toString()}'));
    }
  }

  Future<void> _onCategoriesReorderRequested(
    CategoriesReorderRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.toUpdating());

    try {
      await _categoryRepository.reorderCategories(event.categoryOrders);

      // Reload categories to get the updated order
      if (state.categories.isNotEmpty) {
        final tournamentId = state.categories.first.tournamentId;
        final categories = await _categoryRepository.getTournamentCategories(tournamentId);
        emit(state.toSuccess(categories: categories));
      }
    } catch (e) {
      emit(state.toError('Failed to reorder categories: ${e.toString()}'));
    }
  }

  Future<void> _onDefaultCategoriesCreateRequested(
    DefaultCategoriesCreateRequested event,
    Emitter<CategoryState> emit,
  ) async {
    emit(state.toCreating());

    try {
      final categories = await _categoryRepository.createDefaultCategories(event.tournamentId);
      emit(state.toSuccess(categories: categories));
    } catch (e) {
      emit(state.toError('Failed to create default categories: ${e.toString()}'));
    }
  }
} 