# TODO: Add Booking Cancellation Endpoint

## Steps to Complete

- [x] Add `cancelBooking` function to `backend/controllers/slotController.js`
  - Retrieve booking ID from request params
  - Find booking by ID and validate it exists and is cancellable
  - Update status to 'cancelled' and cancelReason to 'user_cancelled'
  - Save and return success response

- [x] Add new PUT route `/bookings/:bookingId/cancel` to `backend/routes/slotRoutes.js`
  - Use JWT authentication
  - Call the `cancelBooking` controller function

- [x] Test the new endpoint
  - Ensure booking status updates correctly
  - Handle errors like booking not found or already cancelled
  - Verify authentication is enforced
