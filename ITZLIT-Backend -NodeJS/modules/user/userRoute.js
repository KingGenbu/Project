const express = require('express');
const userCtr = require('./userController.js');
const middleware = require('../../middleware.js');
const validationRules = require('./userValidationRules.js');

const userRouter = express.Router();

// Inject Validation Rules
userRouter.use((req, res, next) => {
  req.validations = validationRules.get(req.path);
  next();
});

// Perform Validations
userRouter.use(middleware.reqValidator);

// Routes
userRouter.post('/test', userCtr.test);
userRouter.post('/create', userCtr.create);
userRouter.get('/profile-pic-aws-presinged-url', userCtr.profilePicAWSPreSignedURL);

userRouter.post('/login', userCtr.login);
userRouter.post('/fb-login', userCtr.fbLogin);
userRouter.post('/forget-password', userCtr.forgetPassword);
userRouter.get('/reset-password/:userId/:cToken', userCtr.resetPassword);
userRouter.get('/verify-email/:userId/:vToken', userCtr.verifyEmail);
userRouter.get('/resend-otp', middleware.loadUser, userCtr.resendOtp);
userRouter.get('/verify-number/:vCode', middleware.loadUser, userCtr.verifyNumber);
userRouter.post('/change-password', middleware.loadUser, userCtr.changePassword);
userRouter.get('/me', middleware.loadUser, userCtr.me);
userRouter.post('/logout', middleware.loadUser, userCtr.logout);
userRouter.post('/update-profile', middleware.loadUser, userCtr.updateProfile);
userRouter.post('/send-invitation', middleware.loadUser, userCtr.sendInvitation);

module.exports = userRouter;

