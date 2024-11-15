import 'dart:developer';

import 'package:mongo_dart/mongo_dart.dart';

import '../constants/text_strings.dart';

class MongoDatabase {
  static connect() async {
    var db = await Db.create(MONGO_URL);
    await db.open();
    inspect(db);
    var collection = db.collection(COLLECTION_NAME);
  }
}
