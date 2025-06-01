import 'package:equatable/equatable.dart';
import '../data/models/category_model.dart';

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
  final CategoryBlocStatus status;
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final String? errorMessage;

  const CategoryState({
    this.status = CategoryBlocStatus.initial,
    this.categories = const [],
    this.selectedCategory,
    this.errorMessage,
  });

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
      errorMessage: null,
    );
  }

  CategoryState toCreating() {
    return copyWith(
      status: CategoryBlocStatus.creating,
      errorMessage: null,
    );
  }

  CategoryState toUpdating() {
    return copyWith(
      status: CategoryBlocStatus.updating,
      errorMessage: null,
    );
  }

  CategoryState toDeleting() {
    return copyWith(
      status: CategoryBlocStatus.deleting,
      errorMessage: null,
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
      errorMessage: null,
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