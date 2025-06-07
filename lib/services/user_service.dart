// File: lib/services/user_service.dart
   import 'dart:io'; // For File
   import 'package:appwrite/appwrite.dart';
   import 'package:appwrite/models.dart' as models;
   // flutter_dotenv will be replaced by AppConstants later.
   // For this subtask, we'll include it to keep it self-contained for now.
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   import '../core/constants/app_constants.dart';

   class UserService {
     final Databases databases;
     final Storage storage;
     final Client client; // For constructing file view URLs

     // Temporary direct use of env keys, to be replaced by AppConstants in a later step
     // These should match what AuthController used.
     // static const String _databaseIdKey = 'APPWRITE_DATABASE_ID'; // Replaced by AppConstants
     // static const String _profilesCollectionKey = 'USER_PROFILES_COLLECTION_ID'; // Replaced by AppConstants
     // static const String _bucketIdKey = 'PROFILE_PICTURES_BUCKET_ID'; // Replaced by AppConstants

     // Fallback values if .env keys are not found, mirroring AuthController's behavior
     String get _dbId => dotenv.env[AppConstants.appwriteDatabaseIdKey] ?? AppConstants.defaultDatabaseId;
     String get _collectionId => dotenv.env[AppConstants.appwriteUserProfilesCollectionKey] ?? AppConstants.defaultUserProfilesCollectionId;
     String get _bucketId => dotenv.env[AppConstants.appwriteProfilePicturesBucketKey] ?? AppConstants.defaultProfilePicturesBucketId;


     UserService({required this.databases, required this.storage, required this.client});

     Future<models.Document?> getUserProfile(String userId) async {
       try {
         final result = await databases.listDocuments(
           databaseId: _dbId,
           collectionId: _collectionId,
           queries: [
             Query.equal(AppConstants.userIdField, userId),
             Query.orderDesc(AppConstants.createdAtField), // Get the latest if multiple exist (should not happen with good logic)
             Query.limit(1),
           ],
         );
         if (result.documents.isNotEmpty) {
           return result.documents.first;
         }
         return null;
       } on AppwriteException {
         rethrow;
       }
     }

     Future<bool> checkUsernameAvailability(String username) async {
       try {
         final result = await databases.listDocuments(
           databaseId: _dbId,
           collectionId: _collectionId,
           queries: [Query.equal(AppConstants.usernameField, username), Query.limit(1)],
         );
         return result.documents.isEmpty;
       } on AppwriteException {
         rethrow;
       }
     }

     Future<models.Document> saveUserProfile({
        String? documentId, // If updating an existing document
        required String userId,
        required String username,
        String? profilePictureUrl, // Optional: can be set later
        String? firstName,
        String? lastName,
     }) async {
       Map<String, dynamic> data = {
         AppConstants.userIdField: userId, // Always ensure userId is present
         AppConstants.usernameField: username,
         AppConstants.profilePictureField: profilePictureUrl ?? '', // Default to empty if not provided
         'firstName': firstName ?? '', // Assuming 'firstName' and 'lastName' are actual field names
         'lastName': lastName ?? '',   // If these are also in AppConstants, they should be used.
         AppConstants.updatedAtField: DateTime.now().toUtc().toIso8601String(),
       };

       if (documentId != null) { // Update existing document
         return await databases.updateDocument(
           databaseId: _dbId,
           collectionId: _collectionId,
           documentId: documentId,
           data: data,
         );
       } else { // Create new document
         data[AppConstants.createdAtField] = DateTime.now().toUtc().toIso8601String();
         return await databases.createDocument(
           databaseId: _dbId,
           collectionId: _collectionId,
           documentId: ID.unique(), // Appwrite generates unique ID
           data: data,
           permissions: [ // Apply permissions as AuthController did
             Permission.read(Role.user(userId)),
             Permission.update(Role.user(userId)),
             Permission.delete(Role.user(userId)),
           ],
         );
       }
     }

    Future<models.Document?> setUsernameEmpty(String userId) async {
        // This method reflects the original "deleteUsername" which set the username to ""
        try {
            final models.Document? profile = await getUserProfile(userId);
            if (profile != null) {
                return await databases.updateDocument(
                    databaseId: _dbId,
                    collectionId: _collectionId,
                    documentId: profile.$id,
                    data: {AppConstants.usernameField: ''},
                );
            }
            return null; // Or throw an exception if profile must exist
        } on AppwriteException {
            rethrow;
        }
    }

     Future<String> uploadProfilePictureAndUpdateUser(String userId, File file) async {
       try {
         final uploadedFile = await storage.createFile(
           bucketId: _bucketId,
           fileId: ID.unique(), // Appwrite generates unique ID for file
           file: InputFile.fromPath(path: file.path),
         );

         final fileUrl = '${client.endPoint}/storage/buckets/$_bucketId/files/${uploadedFile.$id}/view?project=${client.config['project']}';

         // After uploading, update the user's profile document
         final models.Document? userProfileDoc = await getUserProfile(userId);
         if (userProfileDoc == null) {
           // This implies a user profile document doesn't exist.
           // Depending on app logic, we might create it here or throw an error.
           // For now, let's assume saveUserProfile should be called first if doc is missing.
           throw Exception('User profile document not found for userId: $userId. Cannot update profile picture.');
         }

         await databases.updateDocument(
           databaseId: _dbId,
           collectionId: _collectionId,
           documentId: userProfileDoc.$id,
           data: {AppConstants.profilePictureField: fileUrl},
         );

         return fileUrl;
       } on AppwriteException {
         rethrow;
       }
     }
   }
