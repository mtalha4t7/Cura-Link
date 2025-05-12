import 'dart:developer';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../constants/text_strings.dart'; // Ensure this path is correct
import 'package:logger/logger.dart';

import '../screens/features/core/screens/Patient/NurseBooking/bid_model.dart';
import '../screens/features/core/screens/Patient/NurseBooking/nurseModel.dart';

// Initialize a logger for better logging
final logger = Logger();

class MongoDatabase {
  static Db? _db;
  static DbCollection? _userPatientCollection;
  static DbCollection? _userLabCollection;
  static DbCollection? _userNurseCollection;
  static DbCollection? _userMedicalStoreCollection;
  static DbCollection? _medicalLabServices;
  static DbCollection? _userVerification;
  static DbCollection? _bookingsCollection;
  static DbCollection? _patientBookingsCollection;
  static DbCollection? _users;
  static DbCollection? _messagesCollection;
  static DbCollection? _labRating;
  static late DbCollection labRatingsCollection;
  static DbCollection? _nurseServiceRequestsCollection;
  static DbCollection? _nurseBidsCollection;
  static DbCollection? _patientNurseBookingsCollection;
  static DbCollection? _nurseReceivedBookingsCollection;
  static DbCollection? _nurseRatingCollection;
  static DbCollection? _medicalBidsCollection;
 static DbCollection? _medicalRequestsCollection;
static DbCollection? _medicalOrdersCollection;
static DbCollection? _completedOrdersCollection;



  // Connect to MongoDB and initialize the collections
  static Future<void> connect() async {
    try {
      // Connect to the MongoDB database
      _db = await Db.create(MONGO_URL);
      await _db!.open();

      // Access the collections from the database
      _userPatientCollection = _db!.collection(USER_PATIENT_COLLECTION_NAME);
      _userLabCollection = _db!.collection(USER_LAB_COLLECTION_NAME);
      _userNurseCollection = _db!.collection(USER_NURSE_COLLECTION_NAME);
      _userMedicalStoreCollection =
          _db!.collection(USER_MEDICAL_STORE_COLLECTION_NAME);
      _medicalLabServices = _db!.collection(LAB_SERVICES);
      _userVerification = _db!.collection(USER_VERIFICATION);
      _bookingsCollection = _db!.collection(LAB_BOOKINGS);
      _patientBookingsCollection = _db!.collection(PATIENT_LAB_BOOKINGS);
      _users = _db!.collection(USERS);
      _messagesCollection = _db!.collection(MESSAGES_COLLECTION_NAME);
      _labRating = _db!.collection(LAB_RATING_COLLECTION);
      labRatingsCollection = _db!.collection('labRatings');
      _nurseServiceRequestsCollection = _db!.collection(NURSE_SERVICE_REQUESTS_COLLECTION);
      _nurseBidsCollection = _db!.collection(NURSE_BIDS_COLLECTION);
      _patientNurseBookingsCollection = _db!.collection(PATIENT_NURSE_BOOKINGS_COLLECTION);
      _nurseReceivedBookingsCollection = _db!.collection(NURSE_RECEIVED_BOOKINGS_COLLECTION);
      _medicalBidsCollection = _db!.collection('storeBids');
      _medicalRequestsCollection = _db!.collection('storeServiceRequests');
      _medicalOrdersCollection = _db!.collection('medicalOrderCollection');
      _nurseRatingCollection = _db!.collection('nurseRating');
      _completedOrdersCollection = _db!.collection('completedOrders');





      // Create geospatial index for nurses
      await _userNurseCollection?.createIndex(
        keys: {'location': '2dsphere'},
        name: 'location_2dsphere',
        background: true,
      );
      logger.i('Created geospatial index for nurses');
      // Optional: Use inspect to debug the database connection
      inspect(_db);

      logger.i('Connected to MongoDB database successfully');
    } catch (e, stackTrace) {
      logger.e('Error connecting to MongoDB', error: e, stackTrace: stackTrace);
      rethrow;
    }



  }

  static DbCollection? get nurseServiceRequests => _nurseServiceRequestsCollection;
  static DbCollection? get nurseBids => _nurseBidsCollection;

  static DbCollection? get userPatientCollection => _userPatientCollection;
  static DbCollection? get userLabCollection => _userLabCollection;
  static DbCollection? get userNurseCollection => _userNurseCollection;
  static DbCollection? get userMedicalStoreCollection =>
      _userMedicalStoreCollection;
  static DbCollection? get medicalLabServices => _medicalLabServices;
  static DbCollection? get userVerification => _userVerification;
  static DbCollection? get bookingsCollection => _bookingsCollection;
  static DbCollection? get patientBookingsCollection =>
      _patientBookingsCollection;
  static DbCollection? get users => _users;
  static DbCollection? get messagesCollection => _messagesCollection;
  static DbCollection? get labRating => _labRating;

  static DbCollection? get patientNurseBookingsCollection => _patientNurseBookingsCollection;
  static DbCollection? get nurseReceivedBookingsCollection => _nurseReceivedBookingsCollection;
  static DbCollection? get nurseServiceRequestsCollection => _nurseServiceRequestsCollection;
  static DbCollection? get nurseBidsCollection => _nurseBidsCollection;
  static DbCollection? get nurseRatingCollection => _nurseRatingCollection;

  static DbCollection? get labRatingCollection => _labRating;
  static Db? get db => _db;
  static DbCollection? get  medicalBidsCollection =>  _medicalBidsCollection;
static DbCollection? get  medicalRequestsCollection =>  _medicalRequestsCollection;
static DbCollection? get  medicalOrdersCollection =>  _medicalOrdersCollection;
static DbCollection? get  completedOrdersCollection =>  _completedOrdersCollection;



  // Close the MongoDB connection
  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
      _userPatientCollection = null;
      _userLabCollection = null;
      _userNurseCollection = null;
      _userMedicalStoreCollection = null;
      _medicalLabServices = null;
      _userVerification = null;
      _bookingsCollection = null;
      _patientBookingsCollection = null;
      _users = null;
      _messagesCollection = null;
      _labRating= null;
      _medicalBidsCollection=null;
      _medicalRequestsCollection=null;
      _medicalOrdersCollection=null;
      _completedOrdersCollection=null;

      logger.i('MongoDB connection closed');
    }
  }

  static Future<Map<String, dynamic>?> getLocationByEmail(String email) async {
    try {
      final List<DbCollection?> collections = [
        _userPatientCollection,
        _userLabCollection,
        _userNurseCollection,
        _userMedicalStoreCollection,
      ];

      for (final collection in collections) {
        if (collection == null) continue;

        final user = await collection.findOne(where.eq('userEmail', email));
        if (user != null && user.containsKey('location')) {
          return user['location'] as Map<String, dynamic>;
        }
      }

      return null; // Not found
    } catch (e, stackTrace) {
      logger.e('Error fetching user location', error: e, stackTrace: stackTrace);
      return null;
    }
  }


  static Future<void> submitStoreBid({
    required String requestId,
    required Map<String, dynamic> bidData,
  }) async {
    try {
      // Validate request ID
      ObjectId requestObjectId;
      try {
        requestObjectId = ObjectId.parse(requestId);
      } catch (e) {
        throw Exception('Invalid request ID format');
      }

      // Check if request exists
      final request = await _medicalRequestsCollection?.findOne(
        where.id(requestObjectId),
      );

      if (request == null) {
        throw Exception('Request not found');
      }

      // Prepare bid document
      final bidDocument = {
        ...bidData,
        'requestId': requestId,
        'status': 'pending',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };
      final request1 = await _medicalBidsCollection?.findOne(
          where.eq('requestId', requestId),
      );
      if(request1==null){
        await _medicalBidsCollection?.insertOne(bidData);
      }else{
        await _medicalBidsCollection?.updateOne(
          where.eq('requestId', requestId),
          modify.push('bids', bidData),
        );
      }

      // Add bid to bids collection



      // Update request with bid reference
      await _medicalRequestsCollection?.updateOne(
        where.id(requestObjectId),
        modify.push('bids', bidDocument),
      );

      logger.i('Store bid submitted successfully for request $requestId');
    } catch (e, stackTrace) {
      logger.e('Error submitting store bid', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }


  static Future<List<Map<String, dynamic>>> getMedicalStores() async {
    try {
      if (_userMedicalStoreCollection == null) {
        logger.w('Medical store collection is not initialized');
        return [];
      }

      // Find all medical stores that are marked as available
      final stores = await _userMedicalStoreCollection?.find(
          where.eq('isAvailable', true)
      ).toList();

      logger.i('Fetched ${stores?.length ?? 0} available medical stores');
      return stores ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching medical stores',
          error: e,
          stackTrace: stackTrace);
      return [];
    }
  }



  static Future<List<Map<String, dynamic>>?> getAvailableNurses() async {
    final collection =  _userNurseCollection; // or "users" if stored there
    final nurses = await collection?.find({'isAvailable': true}).toList();
    return nurses;
  }




    // adding device token if not available
   Future<void> updateDeviceTokenForUser(
       String email,
       String deviceToken,
       ) async {
     final collections = [
       _userPatientCollection,
       _userLabCollection,
       _userNurseCollection,
       _userMedicalStoreCollection,
     ];

     for (var collection in collections) {
       if (collection == null) continue;

       final userDoc = await collection.findOne({"userEmail": email});

       if (userDoc != null) {
         await collection.updateOne(
           where.eq("userEmail", email),
           modify.set("userDeviceToken", deviceToken),
         );
         // Stop after updating in the first matching collection
         break;
       }
     }
  }

 static Future<String?> getDeviceTokenByEmail(String email) async {
    final collections = [
      _userPatientCollection,
      _userLabCollection,
      _userNurseCollection,
      _userMedicalStoreCollection,
    ];

    for (var collection in collections) {
      if (collection == null) continue;

      final userDoc = await collection.findOne({"userEmail": email});

      if (userDoc != null) {
        final existingToken = userDoc['userDeviceToken'];

        // Return token if it exists and is not empty
        if (existingToken != null && existingToken.toString().isNotEmpty) {
          return existingToken.toString();
        }

        // If the document exists but no token — still stop looking in other collections
        break;
      }
    }

    // Return null if not found or token is empty
    return null;
  }
  // Get all bookings for a patient
  static Future<List<Map<String, dynamic>>> getPatientBookings(String patientEmail) async {
    try {
      final bookings = await _patientNurseBookingsCollection?.find(
          where.eq('patientEmail', patientEmail)
              .sortBy('bookingDate', descending: true)
      ).toList();

      return bookings ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching patient bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  static Future<List<Map<String, dynamic>>> getPatientLabBookings(String patientEmail) async {
    try {
      final bookings = await _patientBookingsCollection?.find(
          where.eq('patientUserEmail', patientEmail)
              .sortBy('bookingDate', descending: true)
      ).toList();

      return bookings ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching patient bookings', error: e, stackTrace: stackTrace);
      return [];
    }
  }



  Future<List<Map<String, dynamic>>> getUpcomingBookings(String nurseEmail) async {
    try {
      final bookings = await MongoDatabase.patientNurseBookingsCollection
          ?.find(
        where
            .eq('nurseEmail', nurseEmail)
            .ne('status', 'Completed')
            .ne('status', 'Cancelled')
            .sortBy('bookingDate', descending: false),
      )
          .toList();

      return bookings ?? [];
    } catch (e, stackTrace) {
      print('Error fetching upcoming bookings: $e');
      return [];
    }
  }

// Get all bookings for a nurse
  static Future<List<Map<String, dynamic>>> getNurseBookings(String nurseEmail) async {
    try {
      logger.i('Fetching bookings for nurseEmail: $nurseEmail');

      if (_patientNurseBookingsCollection == null) {
        logger.w('MongoDB collection _patientNurseBookingsCollection is null');
        return [];
      }

      final bookings = await _patientNurseBookingsCollection!
          .find(where.eq('nurseEmail', nurseEmail)
          .sortBy('bookingDate', descending: true))
          .toList();
      final bookings1 = await _patientNurseBookingsCollection!
          .find(where.eq('patientEmail', nurseEmail)
          .sortBy('bookingDate', descending: true))
          .toList();

      logger.i('Fetched ${bookings.length} bookings for $nurseEmail');
      return bookings??bookings1;
    } catch (e, stackTrace) {
      logger.e('Error fetching nurse bookings for $nurseEmail', error: e, stackTrace: stackTrace);
      return [];
    }
  }


  // In MongoDatabase
  static Future<List<Nurse>> getNursesByEmails(List<String> emails) async {
    try {
      final nursesCollection = _db?.collection('userNurse');
      if (nursesCollection == null) return [];

      final query = {'userEmail': {'\$in': emails}};
      final nursesData = await nursesCollection.find(query).toList();
      return nursesData.map((doc) => Nurse.fromMap(doc)).toList();
    } catch (e) {
      print('Error fetching nurses by emails: $e');
      return [];
    }
  }
  static Future<String> createServiceRequest({
    required String patientEmail,
    required String serviceType,
    required LatLng location,
    required String servicePrice,
  }) async {
    try {
      final request = {
        'patientEmail': patientEmail,
        'serviceType': serviceType,
        'servicePrice': servicePrice,
        'location': {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude],
        },
        'status': 'open',
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      final result = await _nurseServiceRequestsCollection?.insertOne(request);

      final String insertedId = result?.id.toHexString() ?? '';

      // ✅ Immediately update the document to include the `requestId` as a string field
      if (insertedId.isNotEmpty) {
        await _nurseServiceRequestsCollection?.updateOne(
          where.eq('_id', result!.id),
          modify.set('requestId', insertedId),
        );
      }

      return insertedId;
    } catch (e, stackTrace) {
      logger.e('Error creating service request', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }



  Future<void> deleteServiceRequestById(String requestId) async {
    try {
      final id = ObjectId.parse(requestId);
      await _nurseServiceRequestsCollection?.deleteOne(where.id(id));
    } catch (e) {
      throw Exception('Error deleting service request: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getNearbyNurses(LatLng location, double maxDistanceKm) async {
    try {
      final nurses = await _userNurseCollection?.find(where.nearSphere(
        'location',
        location.longitude as Geometry,
        minDistance: location.latitude,
        maxDistance: maxDistanceKm * 1000, // Convert km to meters
      )).toList();

      return nurses ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching nearby nurses', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  static Future<String> submitBid({
    required String requestId,
    required String nurseName,
    required String nurseEmail,
    required double price,
    required String serviceName,
  }) async {
    try {
      final bid = {
        'requestId':requestId ,
        'nurseEmail': nurseEmail,
        'price': price,
        'userName':nurseName,
        'status': 'pending',
        'createdAt': DateTime.now(),
        'serviceName':serviceName
      };

      final result = await _nurseBidsCollection?.insertOne(bid);
      return result?.id.toHexString() ?? '';
    } catch (e, stackTrace) {
      logger.e('Error submitting bid', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }


  static Future<List<Bid>> getBidsForRequest(String requestId) async {
    try {
      final bidsCollection = _db?.collection('nurseBids');

      if (bidsCollection == null) {
        print("❌ Bids collection is null!");
        return [];
      }

      // RequestId is stored as plain string, not ObjectId
      final query = {'requestId': requestId};

      final rawBids = await bidsCollection.find(query).toList();

      print("💡 Fetched ${rawBids.length} bids for requestId $requestId");

      return rawBids.map((map) => Bid.fromMap(map)).toList();
    } catch (e, stackTrace) {
      print("❌ Error in getBidsForRequest: $e");
      print(stackTrace);
      return [];
    }
  }



  static Future<void> acceptBid(String bidId) async {
    try {
      final bidObjectId = ObjectId.parse(bidId);

      // Update bid status
      await _nurseBidsCollection?.updateOne(
        where.id(bidObjectId),
        modify.set('status', 'accepted'),
      );

      // Get the associated request
      final bid = await _nurseBidsCollection?.findOne(where.id(bidObjectId));
      final requestId = bid?['requestId'];

      if (requestId != null) {
        // Update request status
        await _nurseServiceRequestsCollection?.updateOne(
          where.id(ObjectId.parse(requestId)),
          modify
            ..set('status', 'accepted')
            ..set('acceptedBidId', bidId),
        );
      }
    } catch (e, stackTrace) {
      logger.e('Error accepting bid', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }



// ========== LAB RATING FUNCTIONS ==========

  /// Insert a new lab rating
  static Future<void> insertLabRating(Map<String, dynamic> rating) async {
    try {
      if (rating.isEmpty ||
          !rating.containsKey('labEmail') ||
          !rating.containsKey('rating') ||
          !rating.containsKey('userEmail') ||  // fixed this
          !rating.containsKey('bookingId')) {
        throw Exception('Invalid rating data: Missing required fields');
      }


      final existingRating = await _labRating?.findOne({
        'userEmail': rating['userEmail'],  // fixed this
        'bookingId': rating['bookingId'],
      });

      if (existingRating != null) {
        throw Exception('you have  already rated this booking');
      }

      rating['createdAt'] ??= DateTime.now().millisecondsSinceEpoch;

      await _labRating?.insertOne(rating);
      logger.i('Lab rating inserted successfully');
    } catch (e, stackTrace) {
      logger.e('Error inserting lab rating', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }



  /// Update an existing lab rating (e.g., user changes their rating)
  static Future<void> updateLabRating(String ratingId, Map<String, dynamic> updatedFields) async {
    try {
      ObjectId id;
      try {
        id = ObjectId.parse(ratingId);
      } catch (e) {
        throw Exception('Invalid rating ID format');
      }

      final modifier = ModifierBuilder();
      updatedFields.forEach((key, value) {
        modifier.set(key, value);
      });

      final result = await _labRating?.updateOne(
        where.id(id),
        modifier,
      );

      if (result?.isSuccess == true) {
        logger.i('Lab rating updated successfully');
      } else {
        logger.w('Lab rating update failed or no changes made');
      }
    } catch (e, stackTrace) {
      logger.e('Error updating lab rating', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetch all ratings for a specific lab
  static Future<List<Map<String, dynamic>>> getLabRatings(String labId) async {
    try {
      var ratings = await _labRating
          ?.find(where.eq('labId', labId).sortBy('createdAt', descending: true))
          .toList();

      logger.i('Fetched ${ratings?.length ?? 0} ratings for labId: $labId');
      return ratings?.map((doc) => doc).toList() ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching lab ratings', error: e, stackTrace: stackTrace);
      return [];
    }
  }


  /// (Optional) Fetch ratings by a specific user
  static Future<List<Map<String, dynamic>>> getUserLabRatings(String userId) async {
    try {
      var ratings = await _labRating
          ?.find(where.eq('userId', userId).sortBy('createdAt', descending: true))
          .toList();

      logger.i('Fetched ${ratings?.length ?? 0} ratings made by userId: $userId');
      return ratings?.map((doc) => doc).toList() ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching user lab ratings', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// (Optional) Delete a specific lab rating
  static Future<void> deleteLabRating(String ratingId) async {
    try {
      ObjectId id;
      try {
        id = ObjectId.parse(ratingId);
      } catch (e) {
        throw Exception('Invalid rating ID format');
      }

      final result = await _labRating?.deleteOne(where.id(id));

      if (result?.isSuccess == true) {
        logger.i('Lab rating deleted successfully');
      } else {
        logger.w('Lab rating deletion failed or rating not found');
      }
    } catch (e, stackTrace) {
      logger.e('Error deleting lab rating', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  //get all  messages globally

  static Future<List<Map<String, dynamic>>> getAllMessages() async {
    try {
      final messages = await _messagesCollection
          ?.find(where.sortBy('timestamp', descending: true))
          .toList();

      return messages?.map((doc) => doc).toList() ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching all messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

// Insert a new message
  static Future<void> insertMessage(Map<String, dynamic> message) async {
    try {
      if (message.isEmpty ||
          !message.containsKey('fromId') ||
          !message.containsKey('toId')) {
        throw Exception('Invalid message data: Missing required fields');
      }

      // Add timestamp if missing
      if (!message.containsKey('sent')) {
        message['sent'] = DateTime.now().millisecondsSinceEpoch.toString();
      }

      await _messagesCollection?.insertOne(message);
      logger.i('Message inserted successfully');
    } catch (e, stackTrace) {
      logger.e('Error inserting message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Fetch messages for a specific user
  static Future<List<Map<String, dynamic>>> findMessagesByUser(
      String userId) async {
    try {
      var messages = await _messagesCollection
          ?.find(where.raw({
            "\$or": [
              {"fromId": userId},
              {"toId": userId}
            ]
          }).sortBy('sent', descending: true))
          .toList();

      return messages?.map((doc) => doc).toList() ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching messages', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Update a message (e.g., mark as read)
  static Future<void> updateMessage(
      String messageId, Map<String, dynamic> updatedFields) async {
    try {
      // Validate ObjectId by attempting to parse it
      ObjectId id;
      try {
        id = ObjectId.parse(messageId);
      } catch (e) {
        throw Exception('Invalid message ID format');
      }

      // Create a ModifierBuilder instance
      final modifier = ModifierBuilder();
      updatedFields.forEach((key, value) {
        modifier.set(key, value);
      });

      // Perform the update operation
      final result = await _messagesCollection?.updateOne(
        where.id(id), // Use the parsed ObjectId
        modifier,
      );

      if (result?.isSuccess == true) {
        logger.i('Message updated successfully');
      } else {
        logger.w('Message update failed or no changes made');
      }
    } catch (e, stackTrace) {
      logger.e('Error updating message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Delete a message
  static Future<void> deleteMessage(String messageId) async {
    try {
      // Validate ObjectId by attempting to parse it
      ObjectId id;
      try {
        id = ObjectId.parse(messageId);
      } catch (e) {
        throw Exception('Invalid message ID format');
      }

      // Perform the delete operation
      final result = await _messagesCollection?.deleteOne(where.id(id));

      if (result?.isSuccess == true) {
        logger.i('Message deleted successfully');
      } else {
        logger.w('Message deletion failed or message not found');
      }
    } catch (e, stackTrace) {
      logger.e('Error deleting message', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Create indexes for messages collection
  static Future<void> createMessagesIndexes() async {
    try {
      await _messagesCollection?.createIndex(keys: {'sent': 1});
      await _messagesCollection?.createIndex(keys: {'fromId': 1, 'toId': 1});
      logger.i('Indexes created successfully for messages collection');
    } catch (e, stackTrace) {
      logger.e('Error creating messages indexes',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
  static Future<Map<String, dynamic>?> getUserLocationByEmail(String email) async {
    try {
      if (_db == null) {
        throw Exception('Database connection is not established');
      }

      List<DbCollection?> collections = [
        _userPatientCollection,
        _userLabCollection,
        _userNurseCollection,
        _userMedicalStoreCollection,
        _medicalLabServices,
        _userVerification,
      ];

      for (var collection in collections) {
        if (collection != null) {
          var user = await collection.findOne({'userEmail': email});
          if (user != null) {
            // Try to get location as Map
            dynamic location = user['location'] ?? user['userAddress'];

            // If location is a Map, return it
            if (location is Map<String, dynamic>) {
              return location;
            }

            // If location is a String (like an address), try to parse it
            if (location is String) {
              try {
                // Example of parsing string to map - adjust based on your actual format
                return {
                  'address': location,
                  'latitude': 0.0, // Default values if not available
                  'longitude': 0.0,
                };
              } catch (e) {
                logger.w('Failed to parse location string: $location');
              }
            }
          }
        }
      }

      logger.w('User not found in any collection for email: $email');
      return null;
    } catch (e, stackTrace) {
      logger.e('Error fetching user location', error: e, stackTrace: stackTrace);
      return null;
    }
  }


  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      if (_db == null) {
        throw Exception('Database connection is not established');
      }

      List<Map<String, dynamic>> allUsers = [];

      // List of all collections
      List<DbCollection?> collections = [
        _userPatientCollection,
        _userLabCollection,
        _userNurseCollection,
        _userMedicalStoreCollection,
        _medicalLabServices,
        _userVerification
      ];

      for (var collection in collections) {
        if (collection != null) {
          var users = await collection.find().toList();
          allUsers.addAll(users.map((doc) => doc)); // Ensure correct casting
        }
      }

      logger.i('Fetched all users successfully');
      return allUsers;
    } catch (e, stackTrace) {
      logger.e('Error fetching all users', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  // Function to insert a user document into the specified collection
  static Future<void> insertUser(
      Map<String, dynamic> user, DbCollection? collection) async {
    try {
      // Validate the input
      if (user.isEmpty || !user.containsKey('userEmail')) {
        throw Exception('Invalid user data: Missing required fields');
      }

      // Check for duplicate email
      final existingUser =
          await collection?.findOne({'userEmail': user['userEmail']});
      if (existingUser != null) {
        throw Exception('User with the same email already exists');
      }

      // Insert the user
      await collection?.insertOne(user);
      logger.i('User inserted successfully into ${collection?.collectionName}');
    } catch (e, stackTrace) {
      logger.e('Error inserting user', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // Function to find a user by email in the specified collection
  static Future<Map<String, dynamic>?> findUser(
      {required String email, required DbCollection? collection}) async {
    try {
      if (email.isEmpty) {
        throw Exception('Email cannot be empty');
      }

      var user = await collection?.findOne({'userEmail': email});
      logger.i(user != null
          ? 'User found in ${collection?.collectionName}'
          : 'User not found in ${collection?.collectionName}');
      return user;
    } catch (e, stackTrace) {
      logger.e('Error finding user', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  static Future<bool> checkVerification({
    required String nic,
    required String licence,
    required DbCollection? collection,
  }) async {
    // Debug: Log the input parameters
    print("checkVerification called with NIC: $nic, Licence: $licence");

    // Check for empty input parameters and throw an exception if invalid
    if (nic.isEmpty || licence.isEmpty) {
      print("Error: NIC or License cannot be empty"); // Debugging message
      throw Exception('NIC or License cannot be empty');
    }

    try {
      // Debug: Log the start of the database query
      print("Querying database for userNic and userLicenseNumber");

      // Query to check if both NIC and License exist in the same document
      var userDoc = await collection?.findOne({
        'userNic': nic,
        'userLicenseNumber':
            licence, // Ensure both fields are in the same document
      });

      // Debug: Log the result of the query
      if (userDoc != null) {
        print("Verification successful: Document found: $userDoc");
        return true;
      } else {
        print("Verification failed: No matching document found.");
        return false;
      }
    } catch (e) {
      // Debug: Log any exception that occurs
      print("Error during checkVerification: $e");
      throw Exception("An error occurred during verification: $e");
    }
  }

  // Add this method to MongoDatabase class
  static Future<List<Map<String, dynamic>>> getNurseServiceRequests(String nurseEmail) async {
    try {
      final requests = await _nurseServiceRequestsCollection?.find(
          where.eq('status', 'open')
              .sortBy('createdAt', descending: true)
      ).toList();

      return requests ?? [];

    } catch (e, stackTrace) {
      logger.e('Error fetching nurse requests', error: e, stackTrace: stackTrace);
      return [];
    }
  }
  static Future<List<Map<String, dynamic>>> getStoreServiceRequests(String nurseEmail) async {
    try {
      final requests = await _medicalRequestsCollection?.find(
          where
              .oneFrom('status', ['open', 'pending'])
              .sortBy('createdAt', descending: true)
      ).toList();

      return requests ?? [];
    } catch (e, stackTrace) {
      logger.e('Error fetching nurse requests', error: e, stackTrace: stackTrace);
      return [];
    }
  }





  // Function to update user details (e.g., after login) in the specified collection
  static Future<void> updateUser(
      Map<String, dynamic> updatedUser, DbCollection? collection) async {
    try {
      var userId = updatedUser['userId'];
      if (userId == null) {
        throw Exception('User ID is required for updating');
      }

      // Create a ModifierBuilder
      final modifier = modify..set('lastLogin', DateTime.now());

      // Set each field in updatedUser
      updatedUser.forEach((key, value) {
        if (key != '_id') {
          // Avoid setting the _id field
          modifier.set(key, value);
        }
      });

      // Update the user document
      await collection?.updateOne(
        where.eq('_id', userId),
        modifier,
      );

      logger.i('User updated successfully in ${collection?.collectionName}');
    } catch (e, stackTrace) {
      logger.e('Error updating user', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }

  // Function to create indexes on the specified collection
  static Future<void> createIndexes(DbCollection? collection) async {
    try {
      await collection?.createIndex(keys: {'userEmail': 1}, unique: true);
      logger.i('Indexes created successfully in ${collection?.collectionName}');
    } catch (e, stackTrace) {
      logger.e('Error creating indexes', error: e, stackTrace: stackTrace);
      rethrow; // Rethrow the exception if needed
    }
  }

  // Specific methods for each collection

  //user verification
  static Future<void> insertVerifiedUsers(Map<String, dynamic> user) async {
    await insertUser(user, _medicalLabServices);
  }

  static Future<Map<String, dynamic>?> findVerifiedUsers(String email) async {
    return await findUser(email: email, collection: _medicalLabServices);
  }

  static Future<void> updateVerifiedUsers(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _medicalLabServices);
  }

  static Future<void> createVerifiedUsersIndexes() async {
    await createIndexes(_medicalLabServices);
  }

  //Lab booking
  static Future<void> insertLabBooking(Map<String, dynamic> user) async {
    await insertUser(user, _bookingsCollection);
  }

  static Future<Map<String, dynamic>?> findBooking(String email) async {
    return await findUser(email: email, collection: _bookingsCollection);
  }

  static Future<void> updateBooking(Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _bookingsCollection);
  }

  static Future<void> createBookingIndexes() async {
    await createIndexes(_bookingsCollection);
  }

//Patient booking
  static Future<void> insertPatientLabBooking(Map<String, dynamic> user) async {
    await insertUser(user, _patientBookingsCollection);
  }

  static Future<Map<String, dynamic>?> findPatientBooking(String email) async {
    return await findUser(email: email, collection: _patientBookingsCollection);
  }

  static Future<void> updatePatientBooking(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _patientBookingsCollection);
  }

  static Future<void> createPatientBookingIndexes() async {
    await createIndexes(_patientBookingsCollection);
  }

  //Lab services
  static Future<void> insertLabServices(Map<String, dynamic> user) async {
    await insertUser(user, _medicalLabServices);
  }

  static Future<Map<String, dynamic>?> findLabServices(String email) async {
    return await findUser(email: email, collection: _medicalLabServices);
  }

  static Future<void> updateLabServices(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _medicalLabServices);
  }

  static Future<void> createLabServicesIndexes() async {
    await createIndexes(_medicalLabServices);
  }

  // Insert user into the userPatient collection
  static Future<void> insertUserPatient(Map<String, dynamic> user) async {
    await insertUser(user, _userPatientCollection);
  }

  // Find user in the userPatient collection
  static Future<Map<String, dynamic>?> findUserPatient(String email) async {
    return await findUser(email: email, collection: _userPatientCollection);
  }

  // Update user in the userPatient collection
  static Future<void> updateUserPatient(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userPatientCollection);
  }

  // Create indexes in the userPatient collection
  static Future<void> createUserPatientIndexes() async {
    await createIndexes(_userPatientCollection);
  }

  // Repeat for userLab, userNurse, and userMedicalStore collections

  static Future<void> insertUserLab(Map<String, dynamic> user) async {
    await insertUser(user, _userLabCollection);
  }

  static Future<Map<String, dynamic>?> findUserLab(String email) async {
    return await findUser(email: email, collection: _userLabCollection);
  }

  static Future<void> updateUserLab(Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userLabCollection);
  }

  static Future<void> createUserLabIndexes() async {
    await createIndexes(_userLabCollection);
  }

  static Future<void> insertUserNurse(Map<String, dynamic> user) async {
    await insertUser(user, _userNurseCollection);
  }

  static Future<Map<String, dynamic>?> findUserNurse(String email) async {
    return await findUser(email: email, collection: _userNurseCollection);
  }

  static Future<void> updateUserNurse(Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userNurseCollection);
  }

  static Future<void> createUserNurseIndexes() async {
    await createIndexes(_userNurseCollection);
  }

  static Future<void> insertUserMedicalStore(Map<String, dynamic> user) async {
    await insertUser(user, _userMedicalStoreCollection);
  }

  static Future<Map<String, dynamic>?> findUserMedicalStore(
      String email) async {
    return await findUser(
        email: email, collection: _userMedicalStoreCollection);
  }

  static Future<void> updateUserMedicalStore(
      Map<String, dynamic> updatedUser) async {
    await updateUser(updatedUser, _userMedicalStoreCollection);
  }

  static Future<void> createUserMedicalStoreIndexes() async {
    await createIndexes(_userMedicalStoreCollection);
  }
}
