import React from "react";
import { Link } from "react-router-dom";

export default () => (
  <div className="vw-100 vh-100 primary-color d-flex align-items-center justify-content-center">
    <div className="jumbotron jumbotron-fluid bg-transparent">
      <div className="container secondary-color">
        <h1 className="display-4">Page Pilot</h1>
        <p className="lead">
          Navigate your PDFs like a pro! Our AI-powered app makes parsing and finding information in PDFs easier than ever before.
        </p>
        <hr className="my-4" />
        <Link
          to="/recipes"
          className="btn btn-lg custom-button"
          role="button"
        >
          Another Page
        </Link>
      </div>
    </div>
  </div>
);
