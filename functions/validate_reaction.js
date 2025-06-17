const sdk = require('node-appwrite');

module.exports = async ({ req, res }) => {
  const client = new sdk.Client()
    .setEndpoint(process.env.APPWRITE_FUNCTION_API_ENDPOINT)
    .setProject(process.env.APPWRITE_FUNCTION_PROJECT_ID)
    .setKey(req.headers['x-appwrite-key']);

  const databases = new sdk.Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const likesCollectionId = process.env.POST_LIKES_COLLECTION_ID;
  const repostsCollectionId = process.env.POST_REPOSTS_COLLECTION_ID;
  const bookmarksCollectionId = process.env.BOOKMARKS_COLLECTION_ID;

  try {
    const payload = JSON.parse(req.payload || '{}');
    const { type, item_id, user_id } = payload;
    if (!type || !item_id || !user_id) {
      throw new Error('type, item_id and user_id are required');
    }

    let collectionId;
    let queries;
    if (type === 'like') {
      collectionId = likesCollectionId;
      queries = [
        sdk.Query.equal('item_id', item_id),
        sdk.Query.equal('user_id', user_id),
      ];
    } else if (type === 'repost') {
      collectionId = repostsCollectionId;
      queries = [
        sdk.Query.equal('post_id', item_id),
        sdk.Query.equal('user_id', user_id),
      ];
    } else if (type === 'bookmark') {
      collectionId = bookmarksCollectionId;
      queries = [
        sdk.Query.equal('post_id', item_id),
        sdk.Query.equal('user_id', user_id),
      ];
    } else {
      throw new Error('invalid type');
    }

    const existing = await databases.listDocuments(databaseId, collectionId, queries);
    if (existing.documents.length > 0) {
      return res.json({ duplicate: true });
    }
    return res.json({ duplicate: false });
  } catch (err) {
    console.error(err);
    return res.json({ error: err.message });
  }
};
