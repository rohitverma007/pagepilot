import React, { useState } from "react";
import axios from "axios";

export default () => {
  const [question, setQuestion] = useState("");
  const [answer, setAnswer] = useState("");

  const handleQuestionChange = e => {
    setQuestion(e.target.value);
  };

  const handleQuestionSubmit = async () => {
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
      axios.defaults.headers.common['X-CSRF-Token'] = csrfToken;
      const response = await axios.post("/answers", { question });
      setAnswer(response.data.answer);
    } catch (error) {
      console.log(error);
      setAnswer("Error getting answer");
    }
  };

  return (
    <div className="vw-100 vh-100 primary-color d-flex align-items-center justify-content-center">
      <div className="jumbotron jumbotron-fluid bg-transparent">
        <div className="container secondary-color">
          <h1 className="display-4">Page Pilot</h1>
          <p className="lead">
            Navigate your PDFs like a pro! Our AI-powered app makes parsing and finding information in PDFs easier than ever before.
          </p>
          <hr className="my-4" />
          <div className="form-group">
            <input
              type="text"
              className="form-control"
              placeholder="Ask a question"
              value={question}
              onChange={handleQuestionChange}
            />
            <button className="btn btn-lg custom-button" onClick={handleQuestionSubmit}>
              Submit
            </button>
          </div>
          {answer && <p>{answer}</p>}
        </div>
      </div>
    </div>
  );
};
