import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

class GetServerKey {

  Future<String> getServerTokenKey() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];
    final client = await clientViaServiceAccount(ServiceAccountCredentials.fromJson({
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
    }),
     scopes,
    );

    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}
