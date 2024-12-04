const bcryptjs = require("bcryptjs");
const jsonWebtoken = require("jsonwebtoken");
const optGenerator = require("otp-generator");
const crypto = require("crypto");
const userModel = require("../data_structure_models/user_schema_model");
const key = "otp-secret-key";

// Handle User SignIn
async function signIn(req, res) {
  try {
    const { userEmail, userPassword } = req.body;

    const isEmailExist = await userModel.findOne({ userEmail });
    if (!isEmailExist) {
      return res
        .status(400)
        .json({ status: "fail", message: "This email is not associated with any user. Try correct email." });
    }

    const passwordCorrect = await bcryptjs.compare(userPassword, isEmailExist.userPassword);
    if (!passwordCorrect) {
      return res
        .status(400)
        .json({ status: "fail", message: "Password is incorrect. Please try again." });
    }

    const tokenJWT = jsonWebtoken.sign({ id: isEmailExist._id }, "secretPass", { expiresIn: "1h" });

    const { userPassword: _, ...userWithoutSensitiveInfo } = isEmailExist._doc;

    return res.status(200).json({
      status: "success",
      message: "Login successful",
      token: tokenJWT,
      user: userWithoutSensitiveInfo,
    });
  } catch (error) {
    console.error("Error in signin:", error);
    return res.status(500).json({ status: "fail", message: "Internal server error" });
  }
}

// Handle User SignUp
async function signUp(req, res) {
  try {
    const { userName, userEmail, userPassword } = req.body;

    const isEmailExist = await userModel.findOne({ userEmail });
    if (isEmailExist) {
      return res.status(400).json({ message: "Email already exists" });
    }

    const securePassword = await bcryptjs.hash(userPassword, 9);
    let userInfo = new userModel({
      userEmail,
      userName,
      userPassword: securePassword,
    });
    userInfo = await userInfo.save();
    return res.json({ userInfo });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: error.message });
  }
}

// Create OTP
async function createOtp(req, res) {
  try {
    const { userPhone } = req.body;

    // Generate OTP
    const otp = optGenerator.generate(4, {
      alphabets: false,
      upperCase: false,
      specialChars: false,
    });

    // Set OTP expiration time (5 minutes)
    const ttl = 5 * 60 * 1000;
    const expires = Date.now() + ttl;
    const data = `${userPhone}.${otp}.${expires}`;
    const hash = crypto.createHmac("sha256", key).update(data).digest("hex");
    const fullHash = `${hash}.${expires}`;

    console.log(`Your OTP is ${otp}`);

    // Send back the OTP hash and expiration time
    return res.status(200).json({
      status: "success",
      message: "OTP sent successfully",
      hash: fullHash,
      otp, // You may not want to send the OTP back in production, use it for testing only
    });
  } catch (error) {
    console.error("Error generating OTP:", error);
    return res.status(500).json({ status: "fail", message: "Internal server error" });
  }
}

// Verify OTP
async function verifyOtp(req, res) {
  try {
    const { userPhone, otp, hash } = req.body;

    let [hashValue, expires] = hash.split(".");

    let now = Date.now();
    if (now > parseInt(expires)) return res.status(400).json({ message: "OTP Expired" });

    let data = `${userPhone}.${otp}.${expires}`;
    let newCalculateHash = crypto.createHmac("sha256", key).update(data).digest("hex");

    if (newCalculateHash === hashValue) {
      return res.status(200).json({ message: "OTP verified successfully" });
    }

    return res.status(400).json({ message: "Invalid OTP" });
  } catch (error) {
    console.error("Error verifying OTP:", error);
    return res.status(500).json({ message: "Internal server error" });
  }
}

module.exports = { signIn, signUp, createOtp, verifyOtp };
