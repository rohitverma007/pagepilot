module AnswersHelper
    # TODO - create OpenAI service instead of having it in helpers

    def get_embedding(text, model)
        openai_client = OpenAI::Client.new(access_token: ENV["OPEN_API_KEY"])
        result = openai_client.embeddings(
            parameters: {
                model: model,
                input: text
        })
        return result["data"][0]["embedding"]
    end

    def get_query_embedding(text)
        return get_embedding(text, "text-search-curie-query-001")
    end

    def get_openai_answer(question, context)
        openai_client = OpenAI::Client.new(access_token: ENV["OPEN_API_KEY"])
        result = openai_client.chat(
            parameters: {
                model: "gpt-3.5-turbo",
                messages: [{
                    role: "user",
                    content: "Hello, I will ask you a question and give you context about a book. Answer the question using the context. Question: #{question}. Context: #{context}"
                }],
            }
        )
        return result
    end
end
