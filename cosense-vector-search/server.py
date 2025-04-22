import sys
import os

from aiohttp import web
from openai import OpenAI
import requests
import requests.auth


SOLR_PREFIX = os.environ["SOLR_PREFIX"]
HTTP_BASIC_AUTH = os.environ["HTTP_BASIC_AUTH"].split(":")
client = OpenAI()

async def handle_query(request):
    query = request.query.get('query')
    if not query:
        return web.json_response({"error": "Missing query parameter"}, status=422)
    collection_name = request.query.get('collection_name')
    if not collection_name:
        return web.json_response({"error": "Missing collection_name parameter"}, status=422)
    response = client.embeddings.create(
        input=query,
        model="text-embedding-3-small",
        dimensions=256,
    )
    vector = response.data[0].embedding
    params = dict(
        q="{!knn f=vector topK=16}[" + ",".join(map(str, vector)) + "]",
        #q="{!knn f=vector topK=16}[0,0,0]"
    )
    print(params["q"])
    resp = requests.get(SOLR_PREFIX+f"/solr/{collection_name}/select", params=params, auth=requests.auth.HTTPBasicAuth(*HTTP_BASIC_AUTH))
    resp.raise_for_status()
    data = resp.json()
    docs = data['response']['docs']
    print(docs)
    ids = [doc['id'] for doc in docs]
    return web.json_response(ids)

if __name__ == '__main__':
    app = web.Application()
    app.router.add_get('/query', handle_query)
    web.run_app(app, port=int(os.environ.get("PORT", 8080)))
