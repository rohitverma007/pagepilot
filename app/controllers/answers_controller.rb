class AnswersController < ActionController::Base
    # TODO - move mongo + pinecone to its own services files
    def create
        asked_question = params[:question]
        book_title = ENV["BOOK_TITLE"] || "the-minimalist-entrepeneur-v1"
        existing_question = Question.where(question:asked_question, book_title:book_title).first()
        if existing_question
            render json: {
                answer: existing_question.answer
            } and return
        end

        mongo_uri = ENV["MONGO_URI"]
        options = { server_api: {version: "1"} }
        mongo_client = Mongo::Client.new(mongo_uri, options)

        pinecone = Pinecone::Client.new
        pinecone_index = pinecone.index("pagepilot")

        question_embedding = helpers.get_query_embedding(asked_question)
        top_match_text = pinecone_index.query(vector: question_embedding, filter: {"title": { "$eq": book_title}})
        matched_ids = []
        top_match_text["matches"].each do |match|
            matched_ids.push(BSON::ObjectId(match["id"]))
        end

        books_collection = mongo_client[:books]
        content_from_mongo = books_collection.find({"_id": {"$in": matched_ids}})

        # Get first 5 results and attach it to context
        # TODO - optimize, truncate to max tokens of gpt-3.5 (4097)
        context = ""
        tokens_remaining_for_context = helpers.get_remaining_context_tokens(asked_question)

        tokens_used_for_context = 0
        content_from_mongo.each do |document|
            if (tokens_used_for_context + document["tokens"].to_i) <= tokens_remaining_for_context
                context = context + document["content"]
                tokens_used_for_context = tokens_used_for_context + document["tokens"].to_i
            else
                remaining_tokens = tokens_remaining_for_context - (tokens_used_for_context)
                context = context + document["content"][0, remaining_tokens]
                break
            end
        end

        answer = helpers.get_openai_completion_answer(asked_question, context)
        answer_content = answer["choices"][0]["text"]
        new_question = Question.create(question:asked_question, answer:answer_content, book_title:book_title)
        # TODO - better error catching/reporting
        render json: {
            answer: answer_content
        }
    end
end