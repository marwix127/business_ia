import 'package:business_ia/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Página para gestionar (editar/eliminar) ejercicios de una categoría específica.
class ExerciseManagementByCategory extends StatefulWidget {
  final String categoria;
  const ExerciseManagementByCategory({required this.categoria, super.key});

  @override
  State<ExerciseManagementByCategory> createState() =>
      _ExerciseManagementByCategoryState();
}

class _ExerciseManagementByCategoryState
    extends State<ExerciseManagementByCategory> {
  final _ejercicioService = EjercicioService();
  late Future<List<Map<String, dynamic>>> _futureEjercicios;

  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _futureEjercicios = _ejercicioService.obtenerPorCategoria(
        widget.categoria,
      );
    });
  }

  Future<void> _confirmarEliminar(Map<String, dynamic> ejercicio) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar ejercicio'),
        content: const Text(
          '¿Seguro que quieres eliminar este ejercicio? Se perderán todos los datos relacionados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _ejercicioService.eliminarEjercicio(ejercicio['id']);
      _refreshList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoria),
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
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureEjercicios,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final ejercicios = snapshot.data!;

          if (ejercicios.isEmpty) {
            return const Center(
              child: Text('No hay ejercicios en esta categoría'),
            );
          }

          return ListView.builder(
            itemCount: ejercicios.length,
            itemBuilder: (context, index) {
              final ejercicio = ejercicios[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(ejercicio['nombre']),
                subtitle: Text(
                  ejercicio['descripcion'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: () => _confirmarEliminar(ejercicio),
                ),
                onTap: () async {
                  await context.push('/add-exercise', extra: ejercicio);
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
