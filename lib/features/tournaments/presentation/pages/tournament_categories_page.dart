import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:teamapp3/features/tournaments/bloc/category_bloc.dart';
import 'package:teamapp3/features/tournaments/bloc/category_event.dart';
import 'package:teamapp3/features/tournaments/bloc/category_state.dart';
import 'package:teamapp3/features/tournaments/data/models/category_model.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/category_list_item.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/add_category_dialog.dart';
import 'package:teamapp3/features/tournaments/presentation/widgets/edit_category_dialog.dart';

class TournamentCategoriesPage extends StatefulWidget {

  const TournamentCategoriesPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });
  final String tournamentId;
  final String tournamentName;

  @override
  State<TournamentCategoriesPage> createState() => _TournamentCategoriesPageState();
}

class _TournamentCategoriesPageState extends State<TournamentCategoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(
          TournamentCategoriesLoadRequested(widget.tournamentId),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.tournamentName} - Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/tournaments'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: BlocConsumer<CategoryBloc, CategoryState>(
        listener: (context, state) {
          if (state.status == CategoryBlocStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'An error occurred'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state.status == CategoryBlocStatus.success) {
            // Show success message only for create/update/delete operations
            if (state.selectedCategory != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Category saved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          if (state.status == CategoryBlocStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Header section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tournament Categories',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Organize teams into different categories (e.g., Men's/Women's, Competitive/Recreational)",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),

              // Categories list
              Expanded(
                child: state.categories.isEmpty
                    ? _buildEmptyState()
                    : _buildCategoriesList(state.categories),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No categories yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add categories to organize teams\ninto different divisions',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Category'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _createDefaultCategories,
            child: const Text('Create Default Categories'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesList(List<CategoryModel> categories) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: categories.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final category = categories[index];
        return CategoryListItem(
          key: ValueKey(category.id),
          category: category,
          onEdit: () => _showEditCategoryDialog(category),
          onDelete: () => _showDeleteConfirmation(category),
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final categories = context.read<CategoryBloc>().state.categories;
    final item = categories.removeAt(oldIndex);
    categories.insert(newIndex, item);

    // Update display order for affected categories
    final categoryOrders = <Map<String, dynamic>>[];
    for (var i = 0; i < categories.length; i++) {
      categoryOrders.add({
        'id': categories[i].id,
        'displayOrder': i + 1,
      });
    }

    context.read<CategoryBloc>().add(
          CategoriesReorderRequested(categoryOrders),
        );
  }

  void _showAddCategoryDialog() {
    // Get the CategoryBloc from the current context before showing the dialog
    final categoryBloc = context.read<CategoryBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AddCategoryDialog(
        tournamentId: widget.tournamentId,
        onCategoryAdded: (categoryData) {
          categoryBloc.add(
                CategoryCreateRequested(
                  tournamentId: widget.tournamentId,
                  name: categoryData['name'] as String,
                  description: categoryData['description'] as String?,
                  maxTeams: categoryData['maxTeams'] as int?,
                  minTeams: categoryData['minTeams'] as int? ?? 2,
                ),
              );
        },
      ),
    );
  }

  void _showEditCategoryDialog(CategoryModel category) {
    // Get the CategoryBloc from the current context before showing the dialog
    final categoryBloc = context.read<CategoryBloc>();
    
    showDialog(
      context: context,
      builder: (context) => EditCategoryDialog(
        category: category,
        onCategoryUpdated: (categoryData) {
          categoryBloc.add(
                CategoryUpdateRequested(
                  categoryId: category.id,
                  name: categoryData['name'] as String?,
                  description: categoryData['description'] as String?,
                  maxTeams: categoryData['maxTeams'] as int?,
                  minTeams: categoryData['minTeams'] as int?,
                ),
              );
        },
      ),
    );
  }

  void _showDeleteConfirmation(CategoryModel category) {
    // Get the CategoryBloc from the current context before showing the dialog
    final categoryBloc = context.read<CategoryBloc>();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'Teams in this category will be moved to "No Category".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              categoryBloc.add(
                    CategoryDeleteRequested(category.id),
                  );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _createDefaultCategories() {
    final categoryBloc = context.read<CategoryBloc>();
    categoryBloc.add(
          DefaultCategoriesCreateRequested(widget.tournamentId),
        );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tournament Categories Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Categories help organize teams into different divisions. Examples:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text("• Men's / Women's / Mixed"),
              Text('• Competitive / Recreational'),
              Text('• Junior / Senior / Open'),
              Text('• Division A / Division B'),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Drag to reorder categories'),
              Text('• Set team limits per category'),
              Text('• Edit names and descriptions'),
              Text('• Teams can be assigned to categories'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
} 