# usage:
# ruby scripts/pdf_to_page_embeddings.rb pdf_file_location/filename.pdf
# example:
# ruby scripts/pdf_to_page_embeddings.rb ../../Downloads/the-minimalist-entrepeneur-v1.pdf
# Required KEYS:
# ENV["OPEN_API_KEY"]
# ENV["MONGO_URI"]
# ENV['PINECONE_API_KEY']
# ENV['PINECONE_ENVIRONMENT']

require 'openai'
require 'tokenizers'
require "pdf-reader"
require 'mongo'
require 'pinecone'

@openai_client = OpenAI::Client.new(access_token: ENV["OPEN_API_KEY"])
mongo_uri = ENV["MONGO_URI"]
options = { server_api: {version: "1"} }
@mongo_client = Mongo::Client.new(mongo_uri, options)

Pinecone.configure do |config|
    config.api_key  = ENV['PINECONE_API_KEY']
    config.environment = ENV['PINECONE_ENVIRONMENT']
end
@pinecone = Pinecone::Client.new


DOC_EMBEDDINGS_MODEL = "text-search-curie-doc-001"
QUERY_EMBEDDINGS_MODEL = "text-search-curie-query-001"

@tokenizer = Tokenizers.from_pretrained("gpt2")

def count_tokens(text)
    return @tokenizer.encode(text).tokens.length()
end

def extract_pages(page_text, index)
    output = []
    if page_text.length() == 0
        return nil
    end
    content = page_text.split().join(" ")
    if (count_tokens(content)+4 < 2046)
        return content, (count_tokens(content)+4)
    else 
        return nil
    end
end

reader = PDF::Reader.new(ARGV[0])

res = []
i = 1
reader.pages.each_with_index do |page, index|
    single_page_content = extract_pages(page.text, index+1)
    res.push(single_page_content)
end

def get_embedding(text, model)
    result = @openai_client.embeddings(
        parameters: {
            model: model,
            input: text
    })
    return result["data"][0]["embedding"]
end

def get_query_embedding(text)
    return get_embedding(text, QUERY_EMBEDDINGS_MODEL)
end

def get_doc_embedding(text)
    return get_embedding(text, DOC_EMBEDDINGS_MODEL)
end

def compute_doc_embeddings(res)
    res.each_with_index do |singlepage, index|
        singlepage_embedding = get_doc_embedding(singlepage[0])
        mongo_doc = {
            title: 'the-minimalist-entrepeneur-v1',
            page_index: index,
            tokens: singlepage[1],
            content: singlepage[0]
        }
        books_collection = @mongo_client[:books]
        insert_to_mongo = books_collection.insert_one(mongo_doc)
        inserted_mongo_id = insert_to_mongo.inserted_id.to_s
        puts inserted_mongo_id
        pinecone_index = @pinecone.index("pagepilot")
        upserted_result = pinecone_index.upsert(
            vectors: [{
                id: inserted_mongo_id,
                metadata: {
                    title: 'the-minimalist-entrepeneur-v1',
                    page_index: index
                },
                values: singlepage_embedding
            }]
        )
        puts upserted_result
    end
end

doc_embeddings = compute_doc_embeddings(res)

# To query:
# text = "During dinner, what does the Time Traveller make disappear?"
# query_embedding = get_query_embedding(text)
# results = pinecone_index.query(vector: query_embedding)
# query mongodb with ids results