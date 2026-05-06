import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../core/security/input_validator.dart';
import '../../../core/security/secure_http_client.dart';
import '../../../core/state/auth_controller.dart';
import '../../../core/state/cart_scope.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey   = GlobalKey<FormState>();
  final _nameCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addrCtrl  = TextEditingController();
  final _cityCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _http      = SecureHttpClient();
  final _auth      = AuthController();

  bool    _loading  = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    _addrCtrl.dispose(); _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Redirigir a login si no está autenticado
    if (!_auth.isLoggedIn) {
      if (mounted) context.go(AppRoutes.login);
      return;
    }

    setState(() { _loading = true; _error = null; });

    final cart = CartScope.read(context);

    // Construir items del pedido
    final items = cart.items.map((item) => {
      'productId': item.product.id,
      'quantity':  item.quantity,
    }).toList();

    // 1. Crear la orden en el backend
    final orderResponse = await _http.post('/api/ordenes', {
      'items':   items,
      'name':    InputValidator.sanitize(_nameCtrl.text.trim()),
      'phone':   _phoneCtrl.text.trim(),
      'address': InputValidator.sanitize(_addrCtrl.text.trim()),
      'city':    InputValidator.sanitize(_cityCtrl.text.trim()),
      if (_notesCtrl.text.trim().isNotEmpty)
        'notes': InputValidator.sanitize(_notesCtrl.text.trim()),
    });

    if (!mounted) return;

    if (!orderResponse.isSuccess) {
      setState(() {
        _loading = false;
        _error = orderResponse.errorMessage ?? 'Error al crear el pedido.';
      });
      return;
    }

    final ordenId = orderResponse.data['ordenId'] as String;

    // 2. Crear sesión de pago
    final paymentResponse = await _http.post('/api/pagos/sesion', {
      'ordenId': ordenId,
    });

    if (!mounted) return;
    setState(() => _loading = false);

    if (paymentResponse.isSuccess) {
      cart.clearCart();
      _showSuccess(ordenId);
    } else {
      setState(() => _error =
          paymentResponse.errorMessage ?? 'Error al procesar el pago.');
    }
  }

  void _showSuccess(String ordenId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(color: AppColors.g9, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_outline, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('¡Pedido confirmado!', style: AppTextStyles.sectionTitle(fontSize: 18)),
          const SizedBox(height: 8),
          Text('Orden #$ordenId', style: AppTextStyles.body(
              fontSize: 12, color: AppColors.midGray)),
          const SizedBox(height: 6),
          Text(
            'Recibirás un correo de confirmación con el seguimiento del envío.',
            style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.home);
              },
              child: const Text('Volver al inicio'),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);

    if (cart.isEmpty) {
      return Scaffold(
        body: Center(child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.midGray),
            const SizedBox(height: 16),
            Text('Tu carrito está vacío', style: AppTextStyles.sectionTitle(fontSize: 18)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.catalog),
              child: const Text('Ver catálogo'),
            ),
          ],
        )),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: RichText(text: TextSpan(children: [
          TextSpan(text: 'Celu', style: AppTextStyles.logoText(fontSize: 18)),
          TextSpan(text: 'Center', style: AppTextStyles.logoText(fontSize: 18)
              .copyWith(color: AppColors.primary)),
        ])),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.lightBorder),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: MediaQuery.of(context).size.width < 700
              ? Column(children: [
                  _AddressForm(formKey: _formKey, nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl, addrCtrl: _addrCtrl,
                      cityCtrl: _cityCtrl, notesCtrl: _notesCtrl),
                  const SizedBox(height: 24),
                  _OrderSummary(cart: cart, loading: _loading,
                      error: _error, onConfirm: _confirmOrder),
                ])
              : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(flex: 3, child: _AddressForm(
                      formKey: _formKey, nameCtrl: _nameCtrl,
                      phoneCtrl: _phoneCtrl, addrCtrl: _addrCtrl,
                      cityCtrl: _cityCtrl, notesCtrl: _notesCtrl)),
                  const SizedBox(width: 32),
                  SizedBox(width: 320, child: _OrderSummary(
                      cart: cart, loading: _loading,
                      error: _error, onConfirm: _confirmOrder)),
                ]),
        ),
      ),
    );
  }
}

// ── Formulario ─────────────────────────────────────────────────────────────
class _AddressForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl, phoneCtrl, addrCtrl, cityCtrl, notesCtrl;

  const _AddressForm({required this.formKey, required this.nameCtrl,
      required this.phoneCtrl, required this.addrCtrl,
      required this.cityCtrl, required this.notesCtrl});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Dirección de envío', style: AppTextStyles.sectionTitle(fontSize: 20)),
        const SizedBox(height: 24),
        const _L('Nombre completo'), const SizedBox(height: 6),
        TextFormField(controller: nameCtrl, validator: InputValidator.fullName,
            decoration: _d('Juan Pérez', Icons.person_outline)),
        const SizedBox(height: 16),
        const _L('Celular'), const SizedBox(height: 6),
        TextFormField(controller: phoneCtrl, keyboardType: TextInputType.phone,
            validator: (v) => InputValidator.required(v, fieldName: 'El celular'),
            decoration: _d('300 123 4567', Icons.phone_outlined)),
        const SizedBox(height: 16),
        const _L('Dirección'), const SizedBox(height: 6),
        TextFormField(controller: addrCtrl, validator: InputValidator.address,
            decoration: _d('Calle 80 # 10-25, Apto 301', Icons.location_on_outlined)),
        const SizedBox(height: 16),
        const _L('Ciudad'), const SizedBox(height: 6),
        TextFormField(controller: cityCtrl,
            validator: (v) => InputValidator.required(v, fieldName: 'La ciudad'),
            decoration: _d('Bogotá', Icons.location_city_outlined)),
        const SizedBox(height: 16),
        const _L('Notas (opcional)'), const SizedBox(height: 6),
        TextFormField(controller: notesCtrl, maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Ej: Portería, dejar con el vecino...',
              filled: true, fillColor: AppColors.surface,
              contentPadding: EdgeInsets.all(14),
            )),
      ]),
    );
  }

  InputDecoration _d(String hint, IconData icon) => InputDecoration(
    hintText: hint, filled: true, fillColor: AppColors.surface,
    prefixIcon: Icon(icon, size: 18, color: AppColors.midGray),
  );
}

class _L extends StatelessWidget {
  final String text;
  const _L(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: AppTextStyles.body(fontSize: 13, weight: FontWeight.w500, color: AppColors.dark));
}

// ── Resumen ─────────────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final dynamic cart;
  final bool loading;
  final String? error;
  final VoidCallback onConfirm;

  const _OrderSummary({required this.cart, required this.loading,
      this.error, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Resumen del pedido', style: AppTextStyles.sectionTitle(fontSize: 16)),
        const SizedBox(height: 16),

        ...cart.items.map<Widget>((item) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(color: item.product.bgColor,
                  borderRadius: BorderRadius.circular(6)),
              child: Center(child: Text(item.product.emoji,
                  style: const TextStyle(fontSize: 20)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.product.name, style: AppTextStyles.body(
                  fontSize: 12, weight: FontWeight.w500),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('x${item.quantity}', style: AppTextStyles.body(
                  fontSize: 11, color: AppColors.midGray)),
            ])),
            Text(item.product.price, style: AppTextStyles.body(
                fontSize: 12, weight: FontWeight.w500)),
          ]),
        )),

        const Divider(), const SizedBox(height: 8),
        _Row('Subtotal', cart.totalFormatted),
        const SizedBox(height: 6),
        const _Row('Envío', 'Gratis', valueColor: AppColors.primary),
        const SizedBox(height: 10),
        const Divider(), const SizedBox(height: 10),
        _Row('Total', cart.totalFormatted, bold: true, valueSize: 18),

        if (error != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFFEECEC),
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFE57373))),
            child: Text(error!, style: AppTextStyles.body(
                fontSize: 12, color: const Color(0xFFD32F2F))),
          ),
        ],

        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: loading ? null : onConfirm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: loading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Confirmar pedido',
                    style: AppTextStyles.btnLabel(fontSize: 14)
                        .copyWith(color: AppColors.white)),
          ),
        ),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_outline, size: 12, color: AppColors.midGray),
          const SizedBox(width: 4),
          Text('Pago 100% seguro', style: AppTextStyles.body(
              fontSize: 11, color: AppColors.midGray)),
        ]),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  final bool bold;
  final double valueSize;
  const _Row(this.label, this.value,
      {this.valueColor, this.bold = false, this.valueSize = 14});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.body(fontSize: 13, color: AppColors.midGray)),
      Text(value, style: bold
          ? AppTextStyles.productPrice(fontSize: valueSize)
          : AppTextStyles.body(fontSize: valueSize,
              color: valueColor ?? AppColors.dark, weight: FontWeight.w500)),
    ]);
  }
}
