class CreateQuestions < ActiveRecord::Migration[7.0]
  def change
    create_table :questions do |t|
      t.string :question
      t.string :answer
      t.string :book_title
      t.string :times_asked

      t.timestamps
    end
  end
end
