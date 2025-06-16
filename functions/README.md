# Appwrite Cloud Functions

This directory contains serverless functions used by the StarChat application. Each function increments counters in the database using Appwrite's `$increment` syntax.

## Functions

- **increment_comment_count** – Adds 1 to the `comment_count` of a post document.
- **increment_reply_count** – Adds 1 to the `reply_count` of a comment document.
- **increment_like_count** – Adds 1 to the `like_count` of a post document.
- **increment_comment_like_count** – Adds 1 to the `like_count` of a comment document.

Each function expects the target document ID in the request body:

```json
{ "post_id": "..." }
{ "comment_id": "..." }
```

## Deployment

1. Zip the desired function file (e.g. `increment_comment_count.js`).
2. In the Appwrite Console, create a new function with runtime **Node.js 18**.
3. Upload the ZIP as the deployment and set the entrypoint to the JS file name.
4. Configure these environment variables for each function:
   - `APPWRITE_ENDPOINT`
   - `APPWRITE_PROJECT_ID`
   - `APPWRITE_API_KEY`
   - `APPWRITE_DATABASE_ID`
   - `FEED_POSTS_COLLECTION_ID` (for post-related functions)
   - `POST_COMMENTS_COLLECTION_ID` (for comment-related functions)
5. Deploy the function and trigger it from the Flutter app via `Functions.createExecution`.

The functions update the counters atomically so concurrent updates are handled safely.
