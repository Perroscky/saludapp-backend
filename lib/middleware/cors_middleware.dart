import 'package:shelf/shelf.dart';

Middleware corsMiddleware() {
  return (Handler handler) {
    return (Request request) async {
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

      final response = await handler(request);
      
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