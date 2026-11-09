import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../domain/plant.dart';
import '../domain/plant_category.dart';

/// Shared add/edit form. It knows nothing about the API: the parent supplies [onSubmit].
class PlantForm extends StatefulWidget {
  const PlantForm({super.key, required this.onSubmit, required this.categories, this.initial});

  final Plant? initial;
  final List<PlantCategory> categories;
  final Future<void> Function(PlantInput input) onSubmit;

  @override
  State<PlantForm> createState() => _PlantFormState();
}

class _PlantFormState extends State<PlantForm> {
  static const _maxImageBytes = 2 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name);
  late final _species = TextEditingController(text: widget.initial?.species);
  late final _location = TextEditingController(text: widget.initial?.location);
  late final _notes = TextEditingController(text: widget.initial?.notes);
  late final _water = TextEditingController(text: '${widget.initial?.wateringIntervalDays ?? 7}');
  late final _fertilize = TextEditingController(text: '${widget.initial?.fertilizingIntervalDays ?? 30}');
  late String _light = widget.initial?.lightLevel ?? 'medium';
  late String _health = widget.initial?.healthStatus ?? 'healthy';
  late int? _categoryId = widget.initial?.plantCategoryId;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _species, _location, _notes, _water, _fertilize]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    if (bytes.length > _maxImageBytes) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('image_too_large'))));
      return;
    }
    setState(() {
      _imageBytes = bytes;
      _imageName = file.name;
    });
  }

  String? _nullIfEmpty(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(PlantInput(
        name: _name.text.trim(),
        species: _nullIfEmpty(_species),
        location: _nullIfEmpty(_location),
        notes: _nullIfEmpty(_notes),
        plantCategoryId: _categoryId,
        lightLevel: _light,
        wateringIntervalDays: int.parse(_water.text.trim()),
        fertilizingIntervalDays: int.parse(_fertilize.text.trim()),
        healthStatus: _health,
        imageBytes: _imageBytes,
        imageName: _imageName,
      ));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return PageFrame(
      maxWidth: 640,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('plant_name_field'),
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: '${context.tr('name')} *'),
                validator: localized(context, Validators.required),
              ),
              gap,
              TextFormField(controller: _species, decoration: InputDecoration(labelText: context.tr('species'))),
              gap,
              TextFormField(controller: _location, decoration: InputDecoration(labelText: context.tr('location'))),
              gap,
              DropdownButtonFormField<int?>(
                key: const Key('plant_category_field'),
                value: _categoryId,
                decoration: InputDecoration(labelText: context.tr('category')),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('—')),
                  for (final c in widget.categories) DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              gap,
              DropdownButtonFormField<String>(
                value: _light,
                decoration: InputDecoration(labelText: context.tr('light_level')),
                items: [for (final l in AppConstants.lightLevels) DropdownMenuItem(value: l, child: Text(context.tr(l)))],
                onChanged: (v) => setState(() => _light = v ?? _light),
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('water_interval_field'),
                      controller: _water,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: context.tr('water_every')),
                      validator: localized(context, Validators.positiveInt),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      key: const Key('fertilize_interval_field'),
                      controller: _fertilize,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: context.tr('fertilize_every')),
                      validator: localized(context, Validators.positiveInt),
                    ),
                  ),
                ],
              ),
              gap,
              DropdownButtonFormField<String>(
                value: _health,
                decoration: InputDecoration(labelText: context.tr('health')),
                items: [for (final h in AppConstants.healthStatuses) DropdownMenuItem(value: h, child: Text(context.tr(h)))],
                onChanged: (v) => setState(() => _health = v ?? _health),
              ),
              gap,
              TextFormField(controller: _notes, maxLines: 3, decoration: InputDecoration(labelText: context.tr('notes'))),
              gap,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(_imageBytes == null ? context.tr('choose_photo') : context.tr('change_photo')),
                ),
              ),
              if (_imageBytes != null) ...[
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.memory(_imageBytes!, height: 140, fit: BoxFit.cover)),
              ],
              const SizedBox(height: 28),
              FilledButton(
                key: const Key('submit_plant'),
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(context.tr('save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
