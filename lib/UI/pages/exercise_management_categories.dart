import 'package:business_ia/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'exercise_management_by_category.dart';

/// Página que muestra categorías para gestionar ejercicios (editar/eliminar).
class ExerciseManagementCategories extends StatefulWidget {
  const ExerciseManagementCategories({super.key});

  @override
  State<ExerciseManagementCategories> createState() =>
      _ExerciseManagementCategoriesState();
}

class _ExerciseManagementCategoriesState
    extends State<ExerciseManagementCategories> {
  final _ejercicioService = EjercicioService();
  late Future<List<String>> _futureCategorias;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _futureCategorias = _ejercicioService.obtenerCategoriasUnicas();
    });
  }

  Future<void> _editarCategoria(String categoria) async {
    final controller = TextEditingController(text: categoria);

    final nuevoNombre = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar categoría'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nuevo nombre',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (nuevoNombre != null &&
        nuevoNombre.isNotEmpty &&
        nuevoNombre != categoria) {
      await _ejercicioService.renombrarCategoria(categoria, nuevoNombre);
      _refreshList();
    }
  }

  Future<void> _eliminarCategoria(String categoria) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Seguro que quieres eliminar la categoría "$categoria"?\n\n'
          'Se eliminarán TODOS los ejercicios de esta categoría.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _ejercicioService.eliminarCategoria(categoria);
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Ejercicios'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await context.push('/add-exercise');
              _refreshList();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _futureCategorias,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categorias = snapshot.data!;

          if (categorias.isEmpty) {
            return const Center(child: Text('No hay categorías'));
          }

          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final categoria = categorias[index];
              return ListTile(
                title: Text(categoria),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editarCategoria(categoria),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: colorScheme.error),
                      onPressed: () => _eliminarCategoria(categoria),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ExerciseManagementByCategory(categoria: categoria),
                    ),
                  );
                  _refreshList();
                },
              );
            },
          );
        },
      ),
    );
  }
}
