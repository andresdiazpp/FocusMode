# TODO — Deuda técnica y decisiones pendientes

Cosas que se dejaron para después con intención. No son bugs, son decisiones conscientes.
Cada entrada dice qué es, por qué se dejó, y dónde está en el código.

---

## 1. Convertir FocusMode en app standalone (como SelfControl)

**Qué falta:** La app solo corre desde Xcode. Para que funcione como SelfControl necesita tres cosas:
- Compilarse y firmarse como app real (`.app` instalable)
- Arrancar sola al encender el Mac (login item via `SMAppService`)
- Vivir en la barra de menús con un icono — sin necesidad de tener una ventana abierta

**Restricción:** Implementar sin Developer ID — solo para uso en el Mac de Andrés. No pagar los $99/año por ahora.

**Por qué se dejó:** Cambiar la arquitectura de la ventana principal a `MenuBarExtra` o `NSStatusItem`, y configurar el login item via `SMAppService`.

**Dónde empezar:** `FocusModeApp.swift` — cambiar `WindowGroup` por `MenuBarExtra` + agregar `SMAppService.mainApp.register()` al activar por primera vez.
