const express = require("express");
const authController = require("../controllers/authController");
const authRouter = express.Router();

// POST request for SignIn
authRouter.post("/api/auth/signin", authController.signIn);

// POST request for SignUp
authRouter.post("/api/auth/signup", authController.signUp);

// POST request for OTP Creation
authRouter.post("/api/auth/createOtp", authController.createOtp);

// POST request for OTP Verification
authRouter.post("/api/auth/verifyOtp", authController.verifyOtp);

module.exports = authRouter;
