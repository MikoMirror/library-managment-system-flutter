const functions = require('firebase-functions');
const nodemailer = require('nodemailer');

// Create email transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: 'Rayham721@gmail.com', // Your library email
    pass: '3851GL351i7'  // Gmail App Password (not your regular password)
  }
});

exports.sendWelcomeEmail = functions.firestore
  .document('users/{userId}')
  .onCreate(async (snap, context) => {
    const userData = snap.data();
    
    const mailOptions = {
      from: 'Library Management System <Library@gmail.com>',
      to: userData.email,
      subject: 'Welcome to Library Management System',
      html: `
        <h2>Welcome to Library Management System</h2>
        <p>Dear ${userData.name},</p>
        <p>Your account has been created successfully.</p>
        <p><strong>Your login credentials:</strong></p>
        <ul>
          <li>Email: ${userData.email}</li>
          <li>Password: ${userData.tempPassword}</li>
          <li>Library Number: ${userData.libraryNumber}</li>
        </ul>
        <p>Please change your password after first login.</p>
        <p>Best regards,<br>Library Management System Team</p>
      `
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log('Welcome email sent to:', userData.email);
    } catch (error) {
      console.error('Error sending email:', error);
    }
}); 