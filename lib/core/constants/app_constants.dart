// File: lib/core/constants/app_constants.dart
   class AppConstants {
     // Environment Variable Keys for .env file
     static const String appwriteEndpointKey = 'APPWRITE_ENDPOINT';
     static const String appwriteProjectIdKey = 'APPWRITE_PROJECT_ID';
     static const String appwriteDatabaseIdKey = 'APPWRITE_DATABASE_ID';
     static const String appwriteUserProfilesCollectionKey = 'USER_PROFILES_COLLECTION_ID';
     static const String appwriteProfilePicturesBucketKey = 'PROFILE_PICTURES_BUCKET_ID';

     // Default Appwrite IDs (used as fallbacks if .env values are missing or for direct use if fixed)
     // It's generally better to ensure these are always correctly set in .env
     static const String defaultAppwriteEndpoint = 'YOUR_APPWRITE_ENDPOINT_HERE'; // e.g. 'https://cloud.appwrite.io/v1'
     static const String defaultAppwriteProjectId = 'YOUR_APPWRITE_PROJECT_ID_HERE';
     static const String defaultDatabaseId = 'StarChat_DB'; // Example, use actual default
     static const String defaultUserProfilesCollectionId = 'user_profiles'; // Example, use actual default
     static const String defaultProfilePicturesBucketId = 'profile_pics'; // Example, use actual default

     // UI & Logic Constants
     static const Duration usernameDebounceDuration = Duration(milliseconds: 500);
     static const int resendCooldownDuration = 60; // in seconds
     static const int otpExpirationDuration = 300; // in seconds

     // Add any other string literals or magic numbers that are widely used
     // For example, if 'userId' is used as a key in maps/JSON for Appwrite data:
     static const String userIdField = 'userId';
     static const String usernameField = 'username';
     static const String profilePictureField = 'profilePicture';
     static const String createdAtField = 'createdAt';
     static const String updatedAtField = 'UpdateAt'; // Note: 'UpdateAt' was used in original AuthController
   }
