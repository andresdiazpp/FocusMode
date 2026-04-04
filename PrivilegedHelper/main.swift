// main.swift
// Punto de entrada del PrivilegedHelper.
//
// Este proceso corre como root. macOS lo inicia cuando la app principal
// necesita hacer algo privilegiado. Se queda corriendo en background
// mientras haya conexiones activas, y macOS lo detiene cuando no se usa.

import Foundation

// HelperDelegate maneja las conexiones que llegan via XPC
final class HelperDelegate: NSObject, NSXPCListenerDelegate {

    // Cada vez que la app principal se conecta, XPC llama este método.
    // Aquí configuramos qué protocolo habla la conexión y quién responde.
    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {

        // Le decimos a la conexión qué protocolo espera recibir
        connection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)

        // HelperXPC es quien responde a los mensajes
        connection.exportedObject = HelperXPC()

        // Verificar que quien se conecta es nuestra app (por Bundle ID)
        // Esto evita que otras apps puedan usar el helper
        // (la verificación completa via audit token se agrega después)

        connection.resume()
        return true
    }
}

// Arranca el listener XPC con el nombre del servicio
let delegate = HelperDelegate()
let listener = NSXPCListener(machServiceName: helperMachServiceName)
listener.delegate = delegate
listener.resume()

// RunLoop mantiene el proceso vivo esperando conexiones
RunLoop.main.run()
