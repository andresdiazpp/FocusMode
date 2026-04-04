# TODO — Deuda técnica y decisiones pendientes

Cosas que se dejaron para después con intención. No son bugs, son decisiones conscientes.
Cada entrada dice qué es, por qué se dejó, y dónde está en el código.

---

## 1. Allow Mode — lógica completa de bloqueo

**Qué falta:** Allow Mode actualmente no bloquea nada. La lógica real (bloquear todo excepto lo que el usuario permite) está pendiente.

**Por qué se dejó:** Se necesita la infraestructura de bloqueo (Pasos 7–10) antes de poder implementar la lógica de Allow Mode correctamente.

**Dónde:** `Domain/BlockEngine.swift` líneas ~58 y ~78 — dos comentarios que dicen "la lógica completa se implementa en Paso 10".

**Qué hacer:** En `activate()`, cuando `session.mode == .allow`, calcular la diferencia: bloquear todos los dominios del sistema EXCEPTO los de `lists.allowWebs`. Para apps: cerrar todo EXCEPTO `lists.allowApps`.

---

## 2. Bloqueo de porn permanente en /etc/hosts (no solo durante sesión)

**Qué falta:** Hoy la blocklist de porn (657k dominios) solo se escribe en `/etc/hosts` cuando hay una sesión activa. Al terminar la sesión, se elimina todo.

**Por qué se dejó:** Requiere cambiar `HostsManaging`, el helper XPC, y `BlockEngine` para distinguir entre bloqueo permanente y bloqueo de sesión.

**Dónde:** `Domain/BlockEngine.swift` — `activate()` y `deactivate()`. `Data/System/HostsManager.swift`. `PrivilegedHelper/HelperXPC.swift`.

**Qué hacer:** Agregar un comando XPC `applyPermanentHostsBlock(domains:)` que escribe los dominios porn fuera del marcador de sesión. Ese bloque no se toca en `removeHostsBlock()`.

---

## 3. DNS CleanBrowsing permanente desde el onboarding

**Qué falta:** Hoy el DNS CleanBrowsing se activa al iniciar sesión y se restaura al terminar. La intención es activarlo una sola vez en el onboarding y nunca restaurarlo.

**Por qué se dejó:** Requiere ajustar `DNSManaging` y `BlockEngine` para no tocar el DNS durante `start`/`stop` de sesión.

**Dónde:** `Domain/BlockEngine.swift` — `activate()` llama `dnsManager.applyCleanBrowsing()` y `deactivate()` llama `dnsManager.restoreDNS()`. `Presentation/Onboarding/PermissionsView.swift`.

**Qué hacer:** Mover la llamada a `applyCleanBrowsing()` al onboarding (una sola vez). Eliminar las llamadas de DNS en `BlockEngine.activate()` y `BlockEngine.deactivate()`.

---

## 4. LicenseValidator — monetización

**Qué falta:** Block Mode y Allow Mode son de pago pero la validación de licencia está comentada. Cualquiera puede usar todos los modos gratis.

**Por qué se dejó:** Se implementa en el paso de monetización (post-Paso 12).

**Dónde:** `Domain/SessionManager.swift` línea ~59 — `guard LicenseValidator.isValid()` está comentado.

**Qué hacer:** Implementar `LicenseValidator` (Paddle, LemonSqueezy, o licencia local) y descomentar el guard.

---

## 5. Migrar SMJobBless → SMAppService

**Qué falta:** `SMJobBless` está deprecado desde macOS 13. El reemplazo moderno es `SMAppService`.

**Por qué se dejó:** Migrar requiere cambiar la estructura del bundle — el `.plist` del helper debe moverse de `Contents/Library/LaunchServices/` a `Contents/Library/LaunchDaemons/`. Es un cambio de infraestructura, no una línea.

**Dónde:** `Data/System/HelperClient.swift` línea ~52 — `SMJobBless(...)` con comentario explicativo.

**Qué hacer:** Reemplazar `installHelperIfNeeded()` usando `SMAppService.daemon(plistName:).register()`. Mover el plist en el bundle. Verificar que el helper sigue instalándose correctamente.

---

## 6. Versión del helper — detección y actualización

**Qué falta:** `installHelperIfNeeded()` compara tamaño de archivo para detectar cambios. Funciona pero es frágil — dos versiones distintas podrían tener el mismo tamaño.

**Por qué se dejó:** Para desarrollo funciona. Se necesita solución robusta antes del primer release.

**Dónde:** `Data/System/HelperClient.swift` — `installHelperIfNeeded()`.

**Qué hacer:** Comparar `CFBundleVersion` del helper instalado contra el del bundle. Si el del bundle es mayor, reinstalar. Requiere leer el Info.plist embebido en el binario instalado.
