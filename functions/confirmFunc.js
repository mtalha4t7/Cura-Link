exports = async ({ token, tokenId, username }) => {
  const Realm = require("realm");

  // Example configuration for Realm app
  const appConfig = {
    id: "cura_link-erilffo", 
    timeout: 1000,
    app: {
      name: "cura_link", // Replace with your app name
      version: "1",        // Replace with your app version
    },
  };

  // Initialize the app
  const app = new Realm.App(appConfig);
  const client = app.auth.emailPassword;

  try {
    // Check if the user is valid using a custom validation function
    const isValidUser = context.functions.execute('isValidUser', username);

    if (isValidUser) {
      // Confirm the user
      await client.confirmUser(token, tokenId);
      return { status: 'success' };
    } else {
      // Send a confirmation email with the token and tokenId
      context.functions.execute('sendConfirmationEmail', username, token, tokenId);
      return { status: 'pending' };
    }
  } catch (error) {
    console.error("Error in email verification:", error);
    // Return fail if any error occurs
    return { status: 'fail' };
  }
};
