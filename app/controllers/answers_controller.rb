class AnswersController < ActionController::Base
    # TODO - move mongo + pinecone to its own services files
    def create
        question = params[:question]

        mongo_uri = ENV["MONGO_URI"]
        options = { server_api: {version: "1"} }
        mongo_client = Mongo::Client.new(mongo_uri, options)

        pinecone = Pinecone::Client.new
        pinecone_index = pinecone.index("pagepilot")

        question_embedding = helpers.get_query_embedding(question)
        top_match_text = pinecone_index.query(vector: question_embedding)
        matched_ids = []
        top_match_text["matches"].each do |match|
            matched_ids.push(BSON::ObjectId(match["id"]))
        end

        books_collection = mongo_client[:books]
        content_from_mongo = books_collection.find({"_id": {"$in": matched_ids}})

        # Get first 5 results and attach it to context
        # TODO - optimize, truncate to max tokens of gpt-3.5 (4097)
        context = ""
        content_from_mongo.each_with_index do |document, index|
            if index <= 5
                context = context + document["content"]
            end
        end
        answer = helpers.get_openai_answer(question, context)

        # TODO - better error catching/reporting
        render json: {
            answer: answer
        }
    end
end