// lib/modelos/mensaje.dart

class Mensaje {
  final String usuario;
  final String mensaje;

  Mensaje({required this.usuario, required this.mensaje});

  // Convertir JSON a un objeto Mensaje
  factory Mensaje.desdeJson(Map<String, dynamic> json) {
    return Mensaje(
      usuario: json['username']?? 'Desconocido',
      mensaje: json['message']?? '',
    );
  }

  // Convertir un objeto Mensaje a JSON
  Map<String, dynamic> aJson() {
    return {
      'usuario': usuario,
      'mensaje': mensaje,

    };
  }
}
