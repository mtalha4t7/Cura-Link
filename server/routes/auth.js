const express = require("express");
const userModel = require("../data_structure_models/user_schema_model");
const authRouter = express.Router();
const bcryptjs = require("bcryptjs");
const jsonWebtoken=require("jsonwebtoken");




authRouter.post("/api/auth/signin", async (request, response) => {
  try {
      const { userEmail, userPassword } = request.body;

      const isEmailExist = await userModel.findOne({ userEmail });
      if (!isEmailExist) {
          return response.status(400).json({ message: "This email is not associated with any user. Try correct email." });
      } else {
          const userDataFromMongoDb = isEmailExist;

          const passwordCorrect = await bcryptjs.compare(userPassword, userDataFromMongoDb.userPassword);
          if (!passwordCorrect) {
              return response.status(400).json({ message: "Password is incorrect. Please try again." });
          } else {
              const tokenJWT = jsonWebtoken.sign({ id: userDataFromMongoDb._id }, "secretPass");

              const { userPassword, ...userDataWithoutSensitiveInformation } = userDataFromMongoDb._doc;

              response.json({ tokenJWT, ...userDataWithoutSensitiveInformation });
              
          }
      }
  } catch (error) {
      console.error(error);
      response.status(500).json({ error: error.message });
  }
});





authRouter.post("/api/auth/signup", async (request, response) => {
  try {
    const { userName, userEmail, userPassword } = request.body;

    const isEmailExist = await userModel.findOne({ userEmail });
    if (isEmailExist) {
      return response.status(400).json({ message: "Email already exists" });
    }

    const securePassword = await bcryptjs.hash(userPassword, 9);
    let userInfo = new userModel({
      userEmail,
      userName,
      userPassword: securePassword,
    });
    userInfo = await userInfo.save();
    response.json({ userInfo });
  } catch (error) {
    console.error(error);
    response.status(500).json({ error: error.message });
  }
});

module.exports = authRouter;
