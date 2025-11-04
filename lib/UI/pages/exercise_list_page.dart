import 'package:business_ia/infrastructure/services/firebase/exercises_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExerciseListPage extends StatefulWidget {
  const ExerciseListPage({super.key});

  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  late Future<List<Map<String, dynamic>>> _futureEjercicios;

  @override
  void initState() {
    super.initState();
    _futureEjercicios = obtenerEjercicios();
  }

  Future<List<Map<String, dynamic>>> obtenerEjercicios() async {
    return EjercicioService().obtenerTodosLosEjercicios();
  }

  void _refreshList() {
    setState(() {
      _futureEjercicios = obtenerEjercicios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              context.push('/add-exercise');
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
          return ListView.builder(
            itemCount: ejercicios.length,
            itemBuilder: (context, index) {
              final ejercicio = ejercicios[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(ejercicio['nombre']),
                subtitle: Text(ejercicio['descripcion'] ?? ''),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: colorScheme.error),
                  onPressed: () async {
                    // Confirma antes de eliminar
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Eliminar ejercicio'),
                        content: const Text(
                          '¿Seguro que quieres eliminar este ejercicio? Se perderan todos los datos relacionados con este ejercicio.',
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
                      await EjercicioService().eliminarEjercicio(
                        ejercicio['id'],
                      );
                      // Refresca la lista
                      _refreshList();
                    }
                  },
                ),
                onTap: () {
                  Navigator.pop(context, ejercicio); // ✅ ya contiene el id
                },
              );
            },
          );
        },
      ),
    );
  }
}
