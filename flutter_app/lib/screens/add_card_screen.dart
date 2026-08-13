import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/word_card.dart';
import '../services/api_service.dart';

class AddCardScreen extends StatefulWidget {
  final List<WordCategory> categories;
  const AddCardScreen({super.key, required this.categories});
  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _english = TextEditingController();
  final _turkish = TextEditingController();
  final _assoc = TextEditingController();
  final _sentence = TextEditingController();
  int? _categoryId;
  String _difficulty = 'medium';
  File? _image;
  bool _saving = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiService().addCard(
        englishWord: _english.text.trim(),
        turkishMeaning: _turkish.text.trim(),
        associationWord: _assoc.text.trim(),
        mnemonicSentence: _sentence.text.trim(),
        categoryId: _categoryId,
        difficulty: _difficulty,
        imageFile: _image,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yeni Kart Ekle')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(14),
                  image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                ),
                child: _image == null
                    ? const Center(child: Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey))
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            _field(_english, 'İngilizce kelime', required: true),
            _field(_turkish, 'Türkçe anlamı', required: true),
            _field(_assoc, 'Çağrışım kelimesi (örn: Laf, Arma, Mont)', required: true),
            _field(_sentence, 'Akılda kalıcı cümle', required: true, maxLines: 3),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('Kategorisiz')),
                ...widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _difficulty,
              decoration: const InputDecoration(labelText: 'Zorluk', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'easy', child: Text('Kolay')),
                DropdownMenuItem(value: 'medium', child: Text('Orta')),
                DropdownMenuItem(value: 'hard', child: Text('Zor')),
              ],
              onChanged: (v) => setState(() => _difficulty = v!),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null : null,
      ),
    );
  }
}
