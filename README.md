# myapp

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Environment Configuration

Create a `.env` file in the project root with the following variables:

```
APPWRITE_ENDPOINT=https://cloud.appwrite.io/v1
APPWRITE_PROJECT_ID=65f5a3e4bd0514b418a4
APPWRITE_DATABASE_ID=StarChat_DB
USER_PROFILES_COLLECTION_ID=user_profiles
APPWRITE_API_KEY=<your_appwrite_api_key>
```

The file is referenced in `pubspec.yaml` so it will be bundled automatically when running the application.

## Updating Collection Permissions

To adjust permissions for the user profiles collection, run the helper script using your Appwrite API key:

```bash
python update_collection_permissions.py
```

Ensure the environment variables above are exported or stored in your `.env` file before running the script.

### Verify Collection Attributes

If you encounter `document_invalid_structure` errors when creating profile documents, check that the collection includes `userId`, `username`, `firstName`, and `lastName` attributes. The helper script does not modify attributes.
