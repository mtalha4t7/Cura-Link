import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:mongo_dart/mongo_dart.dart';

class AuthRouter {
  final DbCollection userCollection;

  AuthRouter(this.userCollection);

  Router get router {
    final router = Router();

    // Sign In Route
    router.post('/api/auth/signin', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);

        final userEmail = data['userEmail'];
        final userPassword = data['userPassword'];

        final user =
            await userCollection.findOne(where.eq('userEmail', userEmail));
        if (user == null) {
          return Response(400,
              body:
                  'This email is not associated with any user. Try correct email.');
        }

        final isPasswordCorrect =
            BCrypt.checkpw(userPassword, user['userPassword']);
        if (!isPasswordCorrect) {
          return Response(400,
              body: 'Password is incorrect. Please try again.');
        }

        final jwt = JWT({'id': user['_id']});
        final token = jwt.sign(SecretKey('secretPass'));

        user.remove('userPassword');
        return Response.ok(
          jsonEncode({
            'tokenJWT': token,
            ...user,
          }),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

    // Sign-Up Route
    router.post('/api/auth/signup', (Request request) async {
      try {
        final payload = await request.readAsString();
        final data = jsonDecode(payload);fl

        final userEmail = data['userEmail'];
        final userPassword = data['userPassword'];
        final userName = data['userName'];
        final userPhone = data['userPhone'];

        // Check if the email is already registered
        final existingUser =
            await userCollection.findOne(where.eq('userEmail', userEmail));
        if (existingUser != null) {
          return Response(400,
              body: 'This email is already registered. Try another one.');
        }

        // Hash the password
        final hashedPassword = BCrypt.hashpw(userPassword, BCrypt.gensalt());

        // Create the user document
        final newUser = {
          'userName': userName,
          'userEmail': userEmail,
          'userPassword': hashedPassword,
          'userPhone': userPhone,
          'createdAt': DateTime.now().toUtc().toString(),
        };

        // Insert the new user into the database
        await userCollection.insertOne(newUser);

        return Response.ok(
          jsonEncode({'message': 'User registered successfully!'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(body: e.toString());
      }
    });

    return router;
  }
}
