import 'package:shelf/shelf.dart';

/// Middleware CORS manual para permitir peticiones desde Flutter
Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
      // Manejar preflight (OPTIONS)
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 
              'Origin, Content-Type, Accept, Authorization, X-Requested-With',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Max-Age': '86400',
        });
      }

      // Procesar la petición normal
      final response = await handler(request);
      
      // Agregar headers CORS a la respuesta
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 
            'Origin, Content-Type, Accept, Authorization, X-Requested-With',
        'Access-Control-Allow-Credentials': 'true',
      });
    };
  };
}