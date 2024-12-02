const mongoose = require("mongoose");

const userSchema = mongoose.Schema({
  userName: {
    type: String,
    required: true,
    trim: true,
  },
  userEmail: {
    type: String,
    required: true,
    trim: true,
    validate: {
      validator: (val) => {
        const emailRes = /^[\w]+(\.[\w]+)*@([\w]+\.)+[a-zA-Z]{2,7}$/;
        return emailRes.test(val);
      },
      message: "Please write a correct email address",
    },
  },
  userPassword: {
    type: String,
    required: true,
  },
  userType: {
    type: String,
    default: "",
  },
  userPhone: {
    type: String,
    default: "",
  },
  userAddress: {
    type: String,
    default: "",
  },
});

const UserModel = mongoose.model("users", userSchema);
module.exports = UserModel;
