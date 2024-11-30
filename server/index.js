const express = require("express");
const authRouter = require("./routes/auth");
const mongoose = require("mongoose");

const PORT = process.env.PORT || 4000;
const app = express();
const MongoDBURL = "mongodb+srv://25362:talha8k83t@curalinkcluster.0xafs.mongodb.net/dbCuraLink?retryWrites=true&w=majority&appName=CuraLinkCluster";

app.use(express.json());
app.use(authRouter);

mongoose
  .connect(MongoDBURL)
  .then(() => {
    console.log("Connection successful");
  })
  .catch((e) => {
    console.log(e);
  });

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Connected at port ${PORT}`);
});
