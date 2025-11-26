import 'package:flutter/material.dart';
import 'package:business_ia/infrastructure/services/firebase/exercises_service.dart';
import 'package:go_router/go_router.dart';

class AddExercisePage extends StatefulWidget {
  final Map<String, dynamic>? exercise;

  const AddExercisePage({super.key, this.exercise});

  @override
  State<AddExercisePage> createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<String> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.exercise != null) {
      _nameController.text = widget.exercise!['nombre'] ?? '';
      _descriptionController.text = widget.exercise!['descripcion'] ?? '';
      _categoryController.text = widget.exercise!['categoria'] ?? '';
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await EjercicioService().obtenerCategoriasUnicas();
    setState(() {
      _categories = cats;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.exercise != null ? 'Editar ejercicio' : 'Añadir ejercicio',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del ejercicio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Añadir descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _categories;
                      }
                      return _categories.where((String option) {
                        return option.toLowerCase().startsWith(
                          textEditingValue.text.toLowerCase(),
                        );
                      });
                    },
                    onSelected: (String selection) {
                      _categoryController.text = selection;
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Categoría (elige o crea una)',
                              border: OutlineInputBorder(),
                            ),
                            onEditingComplete: onEditingComplete,
                            onChanged: (value) {
                              _categoryController.text = value;
                            },
                          );
                        },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final name = _nameController.text.trim();
                      var description = _descriptionController.text.trim();
                      final category =
                          _categoryController.text.trim().isNotEmpty
                          ? _categoryController.text.trim()
                          : _nameController.text.trim();

                      if (name.isEmpty || category.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Completa los campos obligatorios'),
                          ),
                        );
                        return;
                      }
                      if (description.isEmpty) {
                        description = 'Sin descripción';
                      }

                      if (widget.exercise != null) {
                        await EjercicioService()
                            .actualizarEjercicio(widget.exercise!['id'], {
                              'nombre': name,
                              'descripcion': description,
                              'categoria': category,
                            });
                      } else {
                        await EjercicioService().agregarEjercicioPersonalizado({
                          'nombre': name,
                          'descripcion': description,
                          'categoria': category,
                        });
                      }
                      context.pop();
                    },
                    child: Text(
                      widget.exercise != null
                          ? 'Actualizar ejercicio'
                          : 'Guardar ejercicio',
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
