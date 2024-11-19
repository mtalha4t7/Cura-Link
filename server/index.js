const express = require("express");
const mongoose = require("mongoose");

const PORT = process.env.PORT || 3000;
const app = express();

app.use(express.json());

app.listen(PORT, "0.0.0.0", () => {
  console.log(`connected at port ${PORT}`);
});
