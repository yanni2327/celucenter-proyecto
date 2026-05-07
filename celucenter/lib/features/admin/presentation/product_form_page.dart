import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/product_model.dart';

class ProductFormPage extends StatefulWidget {
  final ProductModel? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey    = GlobalKey<FormState>();
  final _http       = SecureHttpClient();
  final _picker     = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _emojiCtrl;

  String    _category  = 'Smartphones';
  String?   _imageUrl;
  Uint8List? _imageBytes;
  bool      _loading   = false;
  bool      _uploading = false;
  String?   _error;

  static const _categories = [
    'Smartphones','Computadoras','Audio','Monitores','Accesorios'
  ];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p    = widget.product;
    _nameCtrl  = TextEditingController(text: p?.name  ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.priceInt.toString() : '');
    _stockCtrl = TextEditingController(text: p?.stock?.toString() ?? '0');
    _descCtrl  = TextEditingController(text: p?.description ?? '');
    _emojiCtrl = TextEditingController(text: p?.emoji ?? '📦');
    _category  = p != null && _categories.contains(p.price.toString())
        ? p.price.toString() : 'Smartphones';
    _imageUrl  = p?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _brandCtrl.dispose();
    _priceCtrl.dispose(); _stockCtrl.dispose();
    _descCtrl.dispose(); _emojiCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, maxHeight: 800, imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() { _imageBytes = bytes; });
    } catch (e) {
      setState(() => _error = 'Error al seleccionar imagen: $e');
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageBytes == null) return _imageUrl;
    setState(() => _uploading = true);

    final base64 = 'data:image/jpeg;base64,${base64Encode(_imageBytes!)}';
    final response = await _http.post('/api/admin/upload/', {
      'image':  base64,
      'folder': 'productos',
    });

    setState(() => _uploading = false);
    return response.isSuccess ? response.data['url'] as String : null;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    String? finalImageUrl = _imageUrl;
    if (_imageBytes != null) {
      finalImageUrl = await _uploadImage();
      if (finalImageUrl == null) {
        setState(() { _loading = false; _error = 'Error al subir la imagen.'; });
        return;
      }
    }

    final body = {
      'name':        _nameCtrl.text.trim(),
      'brand':       _brandCtrl.text.trim(),
      'price':       int.tryParse(_priceCtrl.text.trim()) ?? 0,
      'stock':       int.tryParse(_stockCtrl.text.trim()) ?? 0,
      'description': _descCtrl.text.trim(),
      'emoji':       _emojiCtrl.text.trim(),
      'category':    _category,
      if (finalImageUrl != null) 'imageUrl': finalImageUrl,
    };

    final response = _isEditing
        ? await _http.put('/api/admin/productos/${widget.product!.id}', body)
        : await _http.post('/api/admin/productos', body);

    if (!mounted) return;
    setState(() => _loading = false);

    if (response.isSuccess) {
      Navigator.pop(context, true); // true = refresh list
    } else {
      setState(() => _error = response.errorMessage ?? 'Error al guardar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto',
            style: AppTextStyles.sectionTitle(fontSize: 16)
                .copyWith(color: AppColors.dark)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.lightBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Imagen
                  _SectionTitle('Imagen del producto'),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180, width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.lightBorder,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: _imageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_imageBytes!,
                                  fit: BoxFit.cover, width: double.infinity))
                          : _imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_imageUrl!,
                                      fit: BoxFit.cover, width: double.infinity,
                                      errorBuilder: (_, __, ___) =>
                                          _imagePlaceholder()))
                              : _imagePlaceholder(),
                    ),
                  ),
                  if (_uploading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(color: AppColors.primary),
                    ),
                  const SizedBox(height: 20),

                  // Nombre y marca
                  Row(children: [
                    Expanded(child: _field('Nombre', _nameCtrl,
                        hint: 'Galaxy S25 Ultra', required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _field('Marca', _brandCtrl,
                        hint: 'Samsung', required: true)),
                  ]),
                  const SizedBox(height: 16),

                  // Precio y stock
                  Row(children: [
                    Expanded(child: _field('Precio (COP)', _priceCtrl,
                        hint: '3899000', isNumber: true, required: true)),
                    const SizedBox(width: 16),
                    Expanded(child: _field('Stock', _stockCtrl,
                        hint: '10', isNumber: true, required: true)),
                  ]),
                  const SizedBox(height: 16),

                  // Emoji y categoría
                  Row(children: [
                    SizedBox(
                      width: 100,
                      child: _field('Emoji', _emojiCtrl,
                          hint: '📱', maxLength: 4),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle('Categoría'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(
                              filled: true, fillColor: AppColors.white,
                              counterText: ''),
                          items: _categories.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _category = v ?? _category),
                        ),
                      ],
                    )),
                  ]),
                  const SizedBox(height: 16),

                  // Descripción
                  _SectionTitle('Descripción'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descCtrl, maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Descripción del producto...',
                      filled: true, fillColor: AppColors.white,
                      counterText: '',
                    ),
                  ),

                  // Error
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEECEC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE57373)),
                      ),
                      child: Text(_error!, style: AppTextStyles.body(
                          fontSize: 13, color: const Color(0xFFD32F2F))),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Botones
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(_isEditing ? 'Guardar cambios' : 'Crear producto',
                              style: const TextStyle(color: Colors.white)),
                    )),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.add_photo_alternate_outlined,
          size: 36, color: AppColors.midGray),
      const SizedBox(height: 8),
      Text('Toca para subir imagen',
          style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
      Text('JPG, PNG · máx 10MB',
          style: AppTextStyles.body(fontSize: 11, color: AppColors.lightBorder)),
    ],
  );

  Widget _field(String label, TextEditingController ctrl, {
    String? hint, bool required = false,
    bool isNumber = false, int? maxLength,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionTitle(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLength: maxLength,
        validator: required ? (v) => (v == null || v.trim().isEmpty)
            ? '$label es requerido' : null : null,
        decoration: InputDecoration(
          hintText: hint, filled: true, fillColor: AppColors.white,
          counterText: '',
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.body(fontSize: 13,
          weight: FontWeight.w500, color: AppColors.dark));
}
