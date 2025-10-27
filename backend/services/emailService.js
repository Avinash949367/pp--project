const nodemailer = require('nodemailer');

// Create transporter
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER || 'parkproplus@gmail.com',
        pass: process.env.EMAIL_PASS || 'your-app-password'
    }
});

// Send approval email for documentation process with partnership deed attachment
const sendApprovalEmail = async (toEmail, userName, registrationId, attachments = []) => {
    try {
        const mailOptions = {
            from: process.env.EMAIL_USER || 'parkproplus@gmail.com',
            to: toEmail,
            subject: 'Registration Approved - ParkPro',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #46949d;">Registration Approved!</h2>
                    <p>Dear ${userName},</p>
                    <p>Great news! Your registration has been approved and is ready for the documentation process.</p>
                    <p><strong>Your Registration ID:</strong> ${registrationId}</p>
                    <p>Submit your Documents here - http://127.0.0.1:5502/frontend/registerprocess/document_submission.html</p>
                    <p>Next steps:</p>
                    <ol>
                        <li>Complete the document submission process</li>
                        <li>Get Approved by parkpro+ and get login credentials</li>
                        <li>Login in to your station dashboard & Start listing your parking spots</li>
                    </ol>
                    <p>Thank you for choosing ParkPro!</p>
                    <p>Best regards,<br>The ParkPro Team</p>
                </div>
            `,
            attachments: attachments
        };

        await transporter.sendMail(mailOptions);
        console.log('Approval email sent successfully to:', toEmail);
        return true;
    } catch (error) {
        console.error('Error sending approval email:', error);
        return false;
    }
};

// Send final approval email with login credentials
const sendFinalApprovalEmail = async (toEmail, userName, registrationId, username, password, attachments = []) => {
    try {
        const mailOptions = {
            from: process.env.EMAIL_USER || 'parkproplus@gmail.com',
            to: toEmail,
            subject: 'Registration Final Approval - Your Station is Active!',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #46949d;">🎉 Congratulations! Your Station is Now Active!</h2>
                    <p>Dear ${userName},</p>
                    <p>We are thrilled to inform you that your registration has been successfully approved and your parking station is now active on ParkPro!</p>
                    
                    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #46949d; margin-top: 0;">Your Station Details:</h3>
                        <p><strong>Registration ID:</strong> ${registrationId}</p>
                        <p><strong>Status:</strong> Active</p>
                    </div>

                    <div style="background-color: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #28a745;">
                        <h3 style="color: #155724; margin-top: 0;">🔐 Your Login Credentials:</h3>
                        <p><strong>Login URL:</strong> <a href="http://localhost:5501/frontend/storeAdmin/storeadminlogin.html" style="color: #46949d;">Store Admin Login</a></p>
                        <p><strong>Username (Email):</strong> ${username}</p>
                        <p><strong>Password:</strong> ${password}</p>
                        <p style="color: #721c24; font-size: 14px;"><strong>Important:</strong> Please keep these credentials secure and change your password after first login.</p>
                    </div>

                    <h3 style="color: #46949d;">Next Steps:</h3>
                    <ol>
                        <li>Login to your store admin dashboard using the credentials above</li>
                        <li>Complete your station profile setup</li>
                        <li>Start listing your parking spots</li>
                        <li>Begin accepting bookings and earning revenue!</li>
                    </ol>

                    <p>If you have any questions or need assistance, our support team is here to help at parkproplus@gmail.com</p>
                    
                    <p>Thank you for choosing ParkPro! We look forward to a successful partnership.</p>
                    <p>Best regards,<br>The ParkPro Team</p>
                </div>
            `,
            attachments: attachments
        };

        await transporter.sendMail(mailOptions);
        console.log('Final approval email sent successfully to:', toEmail);
        return true;
    } catch (error) {
        console.error('Error sending final approval email:', error);
        return false;
    }
};

// Send rejection email
const sendRejectionEmail = async (toEmail, userName, reason) => {
    try {
        const mailOptions = {
            from: process.env.EMAIL_USER || 'parkproplus@gmail.com',
            to: toEmail,
            subject: 'Registration Update - ParkPro',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #46949d;">Registration Update</h2>
                    <p>Dear ${userName},</p>
                    <p>We regret to inform you that your registration has been rejected.</p>
                    ${reason ? `<p><strong>Reason:</strong> ${reason}</p>` : ''}
                    <p>If you believe this is an error or would like to reapply, please contact our support team at parkproplus@gmail.com</p>
                    <p>Best regards,<br>The ParkPro Team</p>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log('Rejection email sent successfully to:', toEmail);
        return true;
    } catch (error) {
        console.error('Error sending rejection email:', error);
        return false;
    }
};

// Send payment success email notification
const sendPaymentSuccessEmail = async (toEmail, userName, amount, transactionId) => {
    try {
        const mailOptions = {
            from: process.env.EMAIL_USER || 'parkproplus@gmail.com',
            to: toEmail,
            subject: 'Payment Successful - FASTag Recharge',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #46949d;">Payment Successful! 🎉</h2>
                    <p>Dear ${userName},</p>
                    <p>Your FASTag recharge payment has been successfully processed.</p>

                    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #46949d; margin-top: 0;">Payment Details:</h3>
                        <p><strong>Amount:</strong> ₹${amount}</p>
                        <p><strong>Transaction ID:</strong> ${transactionId}</p>
                        <p><strong>Status:</strong> Completed</p>
                        <p><strong>Date:</strong> ${new Date().toLocaleDateString()}</p>
                    </div>

                    <p>Your FASTag wallet has been credited with ₹${amount}. You can now use your FASTag for toll payments.</p>

                    <p>If you have any questions, please contact our support team at parkproplus@gmail.com</p>

                    <p>Thank you for using ParkPro!</p>
                    <p>Best regards,<br>The ParkPro Team</p>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log('Payment success email sent successfully to:', toEmail);
        return true;
    } catch (error) {
        console.error('Error sending payment success email:', error);
        return false;
    }
};

// Send booking confirmation email
const sendBookingConfirmationEmail = async (toEmail, userName, bookingDetails) => {
    try {
        const { stationName, stationAddress, vehicleNumber, startTime, endTime, amountPaid, paymentMethod, slotId, slotType } = bookingDetails;

        const mailOptions = {
            from: process.env.EMAIL_USER || 'parkproplus@gmail.com',
            to: toEmail,
            subject: 'Booking Confirmed - ParkPro',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <h2 style="color: #46949d;">🎉 Booking Confirmed!</h2>
                    <p>Dear ${userName},</p>
                    <p>Your parking slot has been successfully booked. Here are the details:</p>

                    <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #46949d; margin-top: 0;">Booking Details:</h3>
                        <p><strong>Station:</strong> ${stationName}</p>
                        <p><strong>Address:</strong> ${stationAddress}</p>
                        <p><strong>Slot:</strong> ${slotId} (${slotType})</p>
                        <p><strong>Vehicle:</strong> ${vehicleNumber}</p>
                        <p><strong>Start Time:</strong> ${new Date(startTime).toLocaleString()}</p>
                        <p><strong>End Time:</strong> ${new Date(endTime).toLocaleString()}</p>
                        <p><strong>Amount Paid:</strong> ₹${amountPaid}</p>
                        <p><strong>Payment Method:</strong> ${paymentMethod.toUpperCase()}</p>
                        <p><strong>Status:</strong> Confirmed</p>
                    </div>

                    <p>Please arrive at the station on time. You can view this booking in your profile under "My Bookings".</p>

                    <p>If you have any questions, please contact our support team at parkproplus@gmail.com</p>

                    <p>Thank you for using ParkPro!</p>
                    <p>Best regards,<br>The ParkPro Team</p>
                </div>
            `
        };

        await transporter.sendMail(mailOptions);
        console.log('Booking confirmation email sent successfully to:', toEmail);
        return true;
    } catch (error) {
        console.error('Error sending booking confirmation email:', error);
        return false;
    }
};

module.exports = {
    sendApprovalEmail,
    sendFinalApprovalEmail,
    sendRejectionEmail,
    sendPaymentSuccessEmail,
    sendBookingConfirmationEmail
};
