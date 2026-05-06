import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/product_model.dart';

/// Formulario para crear o editar un producto.
/// Si recibe [product], entra en modo edición.
/// Permite subir imagen a Cloudinary.
class ProductFormPage extends StatefulWidget {
  final ProductModel? product;
  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey    = GlobalKey<FormState>();
  final _http       = SecureHttpClient();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _emojiCtrl;

  String  _category   = 'Smartphones';
  String? _imageUrl;
  String? _imageB64;
  bool    _loading     = false;
  bool    _uploading   = false;
  String? _error;

  final _categories = [
    'Smartphones', 'Computadoras', 'Audio', 'Monitores', 'Accesorios'
  ];

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameCtrl  = TextEditingController(text: p?.name  ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? '');
    _priceCtrl = TextEditingController(
        text: p != null ? p.priceInt.toString() : '');
    _stockCtrl = TextEditingController(
        text: p?.stock?.toString() ?? '0');
    _descCtrl  = TextEditingController(text: p?.description ?? '');
    _emojiCtrl = TextEditingController(text: p?.emoji ?? '📦');
    _category  = p?.price != null ? _categoryFromProduct(p!) : 'Smartphones';
    _imageUrl  = p?.imageUrl;
  }

  String _categoryFromProduct(ProductModel p) {
    if (_categories.contains(p.price.toString())) return p.price.toString();
    return 'Smartphones';
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _brandCtrl.dispose();
    _priceCtrl.dispose(); _stockCtrl.dispose();
    _descCtrl.dispose(); _emojiCtrl.dispose();
    super.dispose();
  }

  // ── Seleccionar imagen del dispositivo ────────────────────────────────────
  Future<void> _pickImage() async {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..click();

    await input.onChange.first;
    if (input.files?.isEmpty ?? true) return;

    final file   = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;

    final result = reader.result as String;
    setState(() {
      _imageB64  = result; // data:image/jpeg;base64,...
      _imageUrl  = result; // preview local
    });
  }

  // ── Subir imagen a Cloudinary via backend ─────────────────────────────────
  Future<String?> _uploadImage() async {
    if (_imageB64 == null) return _imageUrl;

    setState(() => _uploading = true);
    final response = await _http.post('/api/admin/upload/', {
      'image':  _imageB64!,
      'folder': 'productos',
    });
    setState(() => _uploading = false);

    if (response.isSuccess) {
      return response.data['url'] as String;
    }
    return null;
  }

  // ── Guardar producto ──────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() { _loading = true; _error = null; });

    // Subir imagen si hay una nueva
    String? finalImageUrl = _imageUrl;
    if (_imageB64 != null) {
      finalImageUrl = await _uploadImage();
      if (finalImageUrl == null) {
        setState(() {
          _loading = false;
          _error   = 'Error al subir la imagen. Intenta nuevamente.';
        });
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
      Navigator.pop(context);
    } else {
      setState(() => _error = response.errorMessage ?? 'Error al guardar');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar producto' : 'Nuevo producto'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.lightBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Imagen ─────────────────────────────────────────────────
                Text('Imagen del producto',
                    style: AppTextStyles.body(
                        fontSize: 13, weight: FontWeight.w500)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.lightBorder,
                          style: BorderStyle.solid),
                    ),
                    child: _imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  _imagePlaceholder(),
                            ))
                        : _imagePlaceholder(),
                  ),
                ),
                if (_uploading)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(
                        color: AppColors.primary),
                  ),
                const SizedBox(height: 20),

                // ── Campos ─────────────────────────────────────────────────
                Row(children: [
                  Expanded(child: _field('Nombre', _nameCtrl,
                      hint: 'Galaxy S25 Ultra', required: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _field('Marca', _brandCtrl,
                      hint: 'Samsung', required: true)),
                ]),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: _field('Precio (COP)', _priceCtrl,
                      hint: '3899000', isNumber: true, required: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _field('Stock', _stockCtrl,
                      hint: '10', isNumber: true, required: true)),
                ]),
                const SizedBox(height: 14),

                Row(children: [
                  Expanded(child: _field('Emoji', _emojiCtrl,
                      hint: '📱', maxLength: 4)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Categoría',
                            style: AppTextStyles.body(
                                fontSize: 13, weight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _category,
                          decoration: const InputDecoration(
                              filled: true,
                              fillColor: AppColors.surface,
                              counterText: ''),
                          items: _categories.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _category = v ?? _category),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 14),

                Text('Descripción',
                    style: AppTextStyles.body(
                        fontSize: 13, weight: FontWeight.w500)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Descripción del producto...',
                    filled: true, fillColor: AppColors.surface,
                    counterText: '',
                  ),
                ),

                // Error
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEECEC),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFFE57373)),
                    ),
                    child: Text(_error!,
                        style: AppTextStyles.body(
                            fontSize: 13,
                            color: const Color(0xFFD32F2F))),
                  ),
                ],

                const SizedBox(height: 24),

                // Botones
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : Text(_isEditing ? 'Guardar cambios' : 'Crear producto'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.add_photo_alternate_outlined,
          size: 32, color: AppColors.midGray),
      const SizedBox(height: 8),
      Text('Clic para subir imagen',
          style: AppTextStyles.body(
              fontSize: 13, color: AppColors.midGray)),
      Text('JPG, PNG, WebP · máx 10MB',
          style: AppTextStyles.body(
              fontSize: 11, color: AppColors.lightBorder)),
    ],
  );

  Widget _field(String label, TextEditingController ctrl,
      {String? hint,
      bool required = false,
      bool isNumber = false,
      int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTextStyles.body(
                fontSize: 13, weight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType:
              isNumber ? TextInputType.number : TextInputType.text,
          maxLength: maxLength,
          validator: required
              ? (v) => (v == null || v.trim().isEmpty)
                  ? '$label es requerido'
                  : null
              : null,
          decoration: InputDecoration(
            hintText: hint,
            filled: true, fillColor: AppColors.surface,
            counterText: '',
          ),
        ),
      ],
    );
  }
}
