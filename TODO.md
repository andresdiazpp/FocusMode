# TODO — Deuda técnica y decisiones pendientes

Cosas que se dejaron para después con intención. No son bugs, son decisiones conscientes.
Cada entrada dice qué es, por qué se dejó, y dónde está en el código.

---

## 1. Convertir FocusMode en app standalone (como SelfControl)

**Qué falta:** La app solo corre desde Xcode. Para que funcione como SelfControl necesita tres cosas:
- Compilarse y firmarse como app real (`.app` instalable)
- Arrancar sola al encender el Mac (login item via `SMAppService`)
- Vivir en la barra de menús con un icono — sin necesidad de tener una ventana abierta

**Por qué se dejó:** Requiere firma de código real (Developer ID), configurar un entitlements de login item, y cambiar la arquitectura de la ventana principal a `MenuBarExtra` o `NSStatusItem`.

**Dónde empezar:** `FocusModeApp.swift` — cambiar `WindowGroup` por `MenuBarExtra` + agregar `SMAppService.mainApp.register()` al activar por primera vez.
