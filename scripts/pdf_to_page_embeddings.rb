
require 'openai'
require 'tokenizers'
require "pdf-reader"
require 'polars-df'
require 'CSV'

@client = OpenAI::Client.new(access_token: ENV["OPEN_API_KEY"])

DOC_EMBEDDINGS_MODEL = "text-search-curie-doc-001"

@tokenizer = Tokenizers.from_pretrained("gpt2")

def count_tokens(text)
    return @tokenizer.encode(text).tokens.length()
end

def extract_pages(page_text, index)
    output = []
    if page_text.length() == 0
        return []
    end

    content = page_text.split().join(" ")
    puts "page text:"+content
    if (count_tokens(content)+4 < 2046)
        single_page = [
            "Page " + index.to_s,
            content,
            count_tokens(content)+4
        ]
        return single_page
    else 
        return []
    end
end

pdf_filename = ARGV[0]

reader = PDF::Reader.new(ARGV[0])

res = []
i = 1
reader.pages.each_with_index do |page, index|
    single_page_result = extract_pages(page.text, index+1)
    res.append(single_page_result)
    i = i +1    
end

def get_embedding(text, model)
    result = @client.embeddings(
        parameters: {
            model: DOC_EMBEDDINGS_MODEL,
            input: text
    })
    return result["data"][0]["embedding"]
end

def get_doc_embedding(text)
    return get_embedding(text, DOC_EMBEDDINGS_MODEL)
end

def compute_doc_embeddings(res)
    data = []
    res.each_with_index do |singlepage, index|
        data.push(get_doc_embedding(singlepage[1]).insert(0, "Page "+(index+1).to_s))
    end
    return data
end

doc_embeddings = compute_doc_embeddings(res)
CSV.open(pdf_filename+".embeddings.csv", "w") do |csv|
    num_array = ["title"]
    i = 0
    4096.times do
        num_array << i
        i = i + 1
    end
    csv << num_array
    doc_embeddings.each { |row| csv << row }
end

CSV.open(pdf_filename+".pages.csv", "w") do |csv|
    csv << ["title", "content", "tokens"]
    res.each { |row| csv << row }
end