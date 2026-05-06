import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Paleta verde (oscuro → claro) ──────────────────────────────────────────
  static const Color primary    = Color(0xFF419F00); // g1 — botones, CTA
  static const Color g2         = Color(0xFF4EAA03);
  static const Color g3         = Color(0xFF5AB507);
  static const Color g4         = Color(0xFF66C00B);
  static const Color g5         = Color(0xFF72CB10); // hero accent
  static const Color g6         = Color(0xFF89D631);
  static const Color g7         = Color(0xFFA9E159);
  static const Color g8         = Color(0xFFC7EB7A);
  static const Color g9         = Color(0xFFE3F59B); // fondos suaves
  static const Color g10        = Color(0xFFFFFFBB);

  // ── Neutros ────────────────────────────────────────────────────────────────
  static const Color dark       = Color(0xFF1A1A1A); // fondo hero / texto
  static const Color darkCard   = Color(0xFF2A2A2A); // celdas hero
  static const Color darkCard2  = Color(0xFF222222);
  static const Color darkCard3  = Color(0xFF252525);
  static const Color midGray    = Color(0xFF888888);
  static const Color lightBorder= Color(0xFFEEEEEE);
  static const Color surface    = Color(0xFFFAFAFA); // fondo sección categorías
  static const Color white      = Color(0xFFFFFFFF);

  // ── Semánticos ─────────────────────────────────────────────────────────────
  static const Color discount   = Color(0xFFEE5555); // badge -18%
  static const Color statsBar   = Color(0xFFE3F59B); // mismo que g9
  static const Color promoTag   = Color(0xFF1A1A1A); // banda promo

  // ── Colores de fondo para tarjetas de producto ─────────────────────────────
  static const Color prodBg1    = Color(0xFFE3F59B); // verde claro
  static const Color prodBg2    = Color(0xFFF0F0F0); // gris claro
  static const Color prodBg3    = Color(0xFFF5F0FF); // lavanda suave
  static const Color prodBg4    = Color(0xFFFFF3E8); // durazno suave
}
