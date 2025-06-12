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
USER_NAMES_HISTORY_COLLECTION_ID=user_names_history
PROFILE_PICTURES_BUCKET_ID=profile_pics
WATCHLIST_ITEMS_COLLECTION_ID=watchlist_items
PLANETARY_HOUSES_COLLECTION_ID=planetary_houses
PLANET_HOUSE_INTERPRETATIONS_COLLECTION_ID=planet_house_interpretations
APPWRITE_API_KEY=<your_appwrite_api_key>
```

The file is referenced in `pubspec.yaml` so it will be bundled automatically when running the application.

## Updating Collection Permissions

To adjust permissions for the user profiles collection, run the helper script using your Appwrite API key:

```bash
python update_collection_permissions.py
```

Ensure the environment variables above are exported or stored in your `.env` file before running the script.

## Planet Images

The UI displays icons for the nine Vedic planets. Due to repository
restrictions, the image files are not included in source control. Create the
directory `assets/images/planets/` and place the following PNG files in it:

```
sun.png
moon.png
mars.png
mercury.png
jupiter.png
venus.png
saturn.png
rahu.png
ketu.png
```

High quality 128&times;128 transparent icons are recommended. A `.gitkeep` file
is tracked in the folder so the path exists even without the images.

