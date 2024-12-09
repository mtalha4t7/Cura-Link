exports = (
  { token, tokenId, username, password, currentPasswordValid },
  sendEmail,
  securityQuestionAnswer
) => {
  try {
    // Validate input parameters
    if (!username || !password) {
      return { status: 'fail', message: 'Invalid input parameters' };
    }

    if (sendEmail) {
      // Trigger a reset password email
      context.functions.execute(
        'sendResetPasswordEmail', // Ensure this function exists
        username,
        token,
        tokenId
      );
      // Await SDK confirmation with the token and tokenId
      return { status: 'pending' };
    } else if (
      context.functions.execute(
        'validateSecurityQuestionAnswer', // Ensure this function exists
        username,
        securityQuestionAnswer || currentPasswordValid
      )
    ) {
      // Directly reset the user's password
      const Realm = require('realm');
      const appConfig = {
        id: 'cura_link-erilffo',
        timeout: 1000,
        app: {
          name: 'cura_link',
          version: '1',
        },
      };

      const app = new Realm.App(appConfig);
      const client = app.auth.emailPassword;

      client.resetPassword(token, tokenId, password).then(() => {
        return { status: 'success' };
      });
    } else {
      return { status: 'fail', message: 'Security question or password validation failed.' };
    }
  } catch (err) {
    // Log error and fail gracefully
    console.error('Error resetting password:', err);
    return { status: 'fail', message: 'An error occurred while resetting the password.' };
  }
};
