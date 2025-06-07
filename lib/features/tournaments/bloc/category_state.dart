import 'package:equatable/equatable.dart';
import 'package:teamapp3/features/tournaments/data/models/category_model.dart';

enum CategoryBlocStatus {
  initial,
  loading,
  success,
  error,
  creating,
  updating,
  deleting,
}

class CategoryState extends Equatable {

  const CategoryState({
    this.status = CategoryBlocStatus.initial,
    this.categories = const [],
    this.selectedCategory,
    this.errorMessage,
  });
  final CategoryBlocStatus status;
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final String? errorMessage;

  CategoryState copyWith({
    CategoryBlocStatus? status,
    List<CategoryModel>? categories,
    CategoryModel? selectedCategory,
    String? errorMessage,
  }) {
    return CategoryState(
      status: status ?? this.status,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }

  CategoryState toLoading() {
    return copyWith(
      status: CategoryBlocStatus.loading,
    );
  }

  CategoryState toCreating() {
    return copyWith(
      status: CategoryBlocStatus.creating,
    );
  }

  CategoryState toUpdating() {
    return copyWith(
      status: CategoryBlocStatus.updating,
    );
  }

  CategoryState toDeleting() {
    return copyWith(
      status: CategoryBlocStatus.deleting,
    );
  }

  CategoryState toSuccess({
    List<CategoryModel>? categories,
    CategoryModel? selectedCategory,
  }) {
    return copyWith(
      status: CategoryBlocStatus.success,
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory,
    );
  }

  CategoryState toError(String message) {
    return copyWith(
      status: CategoryBlocStatus.error,
      errorMessage: message,
    );
  }

  @override
  List<Object?> get props => [
        status,
        categories,
        selectedCategory,
        errorMessage,
      ];
} 