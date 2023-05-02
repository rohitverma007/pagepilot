module AnswersHelper
    # TODO - create OpenAI service instead of having it in helpers
    def header
        """Sahil Lavingia is the founder and CEO of Gumroad, and the author of the book The Minimalist Entrepreneur (also known as TME). These are questions and answers by him. Please keep your answers to three sentences maximum, and speak in complete sentences. Stop speaking once your point is made.\n\nContext that may be useful, pulled from The Minimalist Entrepreneur:\n"""
    end

    def question_1
        "\n\n\nQ: How to choose what business to start?\n\nA: First off don't be in a rush. Look around you, see what problems you or other people are facing, and solve one of these problems if you see some overlap with your passions or skills. Or, even if you don't see an overlap, imagine how you would solve that problem anyway. Start super, super small."
    end

    def question_2
        "\n\n\nQ: Q: Should we start the business on the side first or should we put full effort right from the start?\n\nA:   Always on the side. Things start small and get bigger from there, and I don't know if I would ever “fully” commit to something unless I had some semblance of customer traction. Like with this product I'm working on now!"
    end

    def question_3
        "\n\n\nQ: Should we sell first than build or the other way around?\n\nA: I would recommend building first. Building will teach you a lot, and too many people use “sales” as an excuse to never learn essential skills like building. You can't sell a house you can't build!"
    end

    def question_4
        "\n\n\nQ: Andrew Chen has a book on this so maybe touché, but how should founders think about the cold start problem? Businesses are hard to start, and even harder to sustain but the latter is somewhat defined and structured, whereas the former is the vast unknown. Not sure if it's worthy, but this is something I have personally struggled with\n\nA: Hey, this is about my book, not his! I would solve the problem from a single player perspective first. For example, Gumroad is useful to a creator looking to sell something even if no one is currently using the platform. Usage helps, but it's not necessary."
    end

    def question_5
        "\n\n\nQ: What is one business that you think is ripe for a minimalist Entrepreneur innovation that isn't currently being pursued by your community?\n\nA: I would move to a place outside of a big city and watch how broken, slow, and non-automated most things are. And of course the big categories like housing, transportation, toys, healthcare, supply chain, food, and more, are constantly being upturned. Go to an industry conference and it's all they talk about! Any industry…"
    end

    def question_6
        "\n\n\nQ: How can you tell if your pricing is right? If you are leaving money on the table\n\nA: I would work backwards from the kind of success you want, how many customers you think you can reasonably get to within a few years, and then reverse engineer how much it should be priced to make that work."
    end
    
    def question_7
        "\n\n\nQ: Why is the name of your book 'the minimalist entrepreneur' \n\nA: I think more people should start businesses, and was hoping that making it feel more “minimal” would make it feel more achievable and lead more people to starting-the hardest step."
    end

    def question_8
        "\n\n\nQ: How long it takes to write TME\n\nA: About 500 hours over the course of a year or two, including book proposal and outline."
    end

    def question_9
        "\n\n\nQ: What is the best way to distribute surveys to test my product idea\n\nA: I use Google Forms and my email list / Twitter account. Works great and is 100% free."
    end

    def question_10
        "\n\n\nQ: How do you know, when to quit\n\nA: When I'm bored, no longer learning, not earning enough, getting physically unhealthy, etc… loads of reasons. I think the default should be to “quit” and work on something new. Few things are worth holding your attention for a long period of time."
    end

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

    def get_openai_completion_answer(question, context)
        openai_client = OpenAI::Client.new(access_token: ENV["OPEN_API_KEY"])
        prompt = create_openai_prompt(question, context)
        openai_client.completions(
            parameters: {
                temperature: 0.0,
                max_tokens: 150,
                model: "text-davinci-003",
                prompt: prompt
            }
        )
    end

    def count_tokens(text)
        tokenizer = Tokenizers.from_pretrained("gpt2")
        return tokenizer.encode(text).tokens.length()
    end


    def prompt_without_context(question)
        return header+question_1+question_2+question_3+question_4+question_5+question_6+question_7+question_8+question_9+question_10+question
    end

    def get_remaining_context_tokens(question)
        max_tokens = (4096-150-200) #leave a few for error etc.
        return (max_tokens - count_tokens(prompt_without_context(question)))
    end

    def create_openai_prompt(question, context)
        return header+context+question_1+question_2+question_3+question_4+question_5+question_6+question_7+question_8+question_9+question_10+"\n\n\nQ: "+question+"\n\nA: "
    end
end
