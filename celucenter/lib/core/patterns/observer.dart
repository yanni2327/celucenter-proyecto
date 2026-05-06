// ─────────────────────────────────────────────────────────────────────────────
//  PATRÓN OBSERVER — CeluCenter
//
//  Definición:
//  El patrón Observer establece una relación uno-a-muchos entre objetos.
//  Cuando el objeto "Sujeto" (Observable) cambia de estado, notifica
//  automáticamente a todos sus "Observadores" (Observer) registrados.
//
//  En CeluCenter se aplica en tres contextos:
//    1. Carrito de compras  → CartObservable / CartObserver
//    2. Autenticación       → AuthObservable / AuthObserver
//    3. Catálogo            → ProductObservable / ProductObserver
// ─────────────────────────────────────────────────────────────────────────────

// ══════════════════════════════════════════════════════════════════════════════
//  INTERFACES BASE
// ══════════════════════════════════════════════════════════════════════════════

/// Interfaz del Observador.
/// Cualquier clase que quiera recibir notificaciones debe implementarla.
abstract interface class Observer<T> {
  /// Método llamado automáticamente cuando el Sujeto cambia.
  void onEvent(T event);
}

/// Interfaz del Sujeto (Observable).
/// Mantiene la lista de observadores y los notifica ante cambios.
abstract interface class Observable<T> {
  /// Registra un observador para recibir notificaciones.
  void addObserver(Observer<T> observer);

  /// Elimina un observador — ya no recibirá notificaciones.
  void removeObserver(Observer<T> observer);

  /// Notifica a todos los observadores registrados con un evento.
  void notifyObservers(T event);
}

// ══════════════════════════════════════════════════════════════════════════════
//  IMPLEMENTACIÓN BASE REUTILIZABLE
//  Las subclases solo llaman a notifyObservers() cuando cambian.
// ══════════════════════════════════════════════════════════════════════════════

/// Implementación concreta de Observable que cualquier controlador puede extender.
/// Gestiona la lista de observadores y el mecanismo de notificación.
abstract class BaseObservable<T> implements Observable<T> {
  final List<Observer<T>> _observers = [];

  @override
  void addObserver(Observer<T> observer) {
    if (!_observers.contains(observer)) {
      _observers.add(observer);
    }
  }

  @override
  void removeObserver(Observer<T> observer) {
    _observers.remove(observer);
  }

  @override
  void notifyObservers(T event) {
    // Iterar sobre una copia para evitar errores si un observer
    // se elimina a sí mismo durante la notificación.
    for (final observer in List<Observer<T>>.from(_observers)) {
      observer.onEvent(event);
    }
  }

  /// Cantidad de observadores actualmente registrados.
  int get observerCount => _observers.length;
}
