const express = require("express");
const mongoose = require("mongoose");

const PORT = process.env.PORT || 4000;
const app = express();
const DB =
    "mongodb+srv://25362:talha8k83t@curalinkcluster.0xafs.mongodb.net/dbCuraLink?retryWrites=true&w=majority&appName=CuraLinkCluster";
const COLLECTION_NAME = "users";

mongoose.connect(DB).then(() => {
  console.log("Connection successful");
}).catch((e)=> {
  console.log(e);
});

app.use(express.json());

app.listen(PORT, "0.0.0.0", () => {
  console.log(`connected at port ${PORT}`);
});
