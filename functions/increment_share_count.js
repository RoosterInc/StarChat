const sdk = require('node-appwrite');

module.exports = async ({ req, res }) => {
  const client = new sdk.Client()
    .setEndpoint(process.env.APPWRITE_ENDPOINT)
    .setProject(process.env.APPWRITE_PROJECT_ID)
    .setKey(process.env.APPWRITE_API_KEY);

  const databases = new sdk.Databases(client);
  const databaseId = process.env.APPWRITE_DATABASE_ID;
  const collectionId = process.env.FEED_POSTS_COLLECTION_ID;

  try {
    const { post_id } = JSON.parse(req.payload || '{}');
    if (!post_id) {
      throw new Error('post_id is required');
    }
    await databases.updateDocument(databaseId, collectionId, post_id, {
      share_count: { '$increment': 1 }
    });
    return res.json({ success: true });
  } catch (err) {
    console.error(err);
    return res.json({ error: err.message });
  }
};
