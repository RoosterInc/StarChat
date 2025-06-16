# Appwrite Cloud Functions

This directory contains serverless functions used by the StarChat application. Each function modifies counter fields using Appwrite's `$increment` or `$decrement` syntax.

## Required Functions

The app expects the following cloud functions to exist. Both increment and decrement variants are needed so counters remain accurate when users undo actions.

- `increment_comment_count` / `decrement_comment_count`
- `increment_reply_count` / `decrement_reply_count`
- `increment_like_count` / `decrement_like_count`
- `increment_comment_like_count` / `decrement_comment_like_count`
- `increment_repost_count` / `decrement_repost_count`
- `increment_bookmark_count` / `decrement_bookmark_count`
- `increment_share_count` / `decrement_share_count`

## Sample Payloads

Each function expects a JSON payload identifying the target document:

```json
{ "post_id": "<post document id>" }
{ "comment_id": "<comment document id>" }
```

Use `post_id` for post related counters (likes, comments, reposts, bookmarks, shares) and `comment_id` for comment related counters (replies and comment likes).

## Environment Variables

All functions require these environment variables:

- `APPWRITE_ENDPOINT`
- `APPWRITE_PROJECT_ID`
- `APPWRITE_API_KEY`
- `APPWRITE_DATABASE_ID`
- `FEED_POSTS_COLLECTION_ID` (for post counters)
- `POST_COMMENTS_COLLECTION_ID` (for comment counters)

## Deployment

1. Zip the desired function file (for example `increment_comment_count.js`).
2. In the Appwrite Console, create a new function with runtime **Node.js 18**.
3. Upload the ZIP as the deployment and set the entrypoint to the JS file name.
4. Configure the environment variables listed above.
5. Deploy the function and trigger it from the Flutter app via `Functions.createExecution`.

These cloud functions must be deployed in Appwrite for like, comment, repost, bookmark and share counters to update correctly. They update counter values atomically so concurrent updates are handled safely.
