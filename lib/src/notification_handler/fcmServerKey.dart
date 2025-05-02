import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {
  Future<String> serverToken() async {
    final credentials = ServiceAccountCredentials.fromJson({
      "type": dotenv.env['FIREBASE_TYPE'],
      "project_id": dotenv.env['FIREBASE_PROJECT_ID'],
      "private_key_id": dotenv.env['FIREBASE_PRIVATE_KEY_ID'],
      "private_key": dotenv.env['FIREBASE_PRIVATE_KEY']?.replaceAll(r'\n', '\n'),
      "client_email": dotenv.env['FIREBASE_CLIENT_EMAIL'],
      "client_id": dotenv.env['FIREBASE_CLIENT_ID'],
      "auth_uri": dotenv.env['FIREBASE_AUTH_URI'],
      "token_uri": dotenv.env['FIREBASE_TOKEN_URI'],
      "auth_provider_x509_cert_url": dotenv.env['FIREBASE_AUTH_PROVIDER_CERT_URL'],
      "client_x509_cert_url": dotenv.env['FIREBASE_CLIENT_CERT_URL'],
      "universe_domain": dotenv.env['FIREBASE_UNIVERSE_DOMAIN']
    });

    final scopes = [
      'https://www.googleapis.com/auth/cloud-platform',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final client = await clientViaServiceAccount(credentials, scopes);
    return client.credentials.accessToken.data;
  }
}
