import os
from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.permission import Permission
from appwrite.role import Role

def main():
    endpoint = os.environ.get("APPWRITE_ENDPOINT")
    project = os.environ.get("APPWRITE_PROJECT_ID")
    api_key = os.environ.get("APPWRITE_API_KEY")
    database_id = os.environ.get("APPWRITE_DATABASE_ID")
    collection_id = os.environ.get("USER_PROFILES_COLLECTION_ID")

    if not all([endpoint, project, api_key, database_id, collection_id]):
        raise RuntimeError("Missing required environment variables")

    client = Client()
    client.set_endpoint(endpoint).set_project(project).set_key(api_key)

    databases = Databases(client)
    collection = databases.get_collection(database_id=database_id, collection_id=collection_id)

    permissions = [
        Permission.create(Role.users()),
        Permission.read(Role.any()),
        Permission.update(Role.users()),
        Permission.delete(Role.users()),
    ]

    databases.update_collection(
        database_id=database_id,
        collection_id=collection_id,
        name=collection['name'],
        permissions=permissions,
        document_security=True,
    )
    print(f"Collection '{collection['name']}' permissions updated")

if __name__ == '__main__':
    main()
