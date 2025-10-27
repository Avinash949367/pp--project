# Toll Payment Implementation Task

## Task Description
Implement toll payment functionality that updates the user's transaction history when a toll is paid. This involves deducting the toll amount from the user's wallet balance and recording the transaction.

## Steps to Complete
- [ ] Add `payToll` function in backend/controllers/fastagController.js
  - Accept toll amount and location in request body
  - Validate user has sufficient wallet balance
  - Deduct toll amount from user's walletBalance
  - Create FastagTransaction record with type 'toll_payment'
  - Return updated balance and transaction details
- [ ] Add POST /pay-toll route in backend/routes/fastagRoutes.js
  - Import and use the new payToll controller function
  - Ensure authentication middleware is applied
- [ ] Test the toll payment endpoint
  - Verify wallet deduction works correctly
  - Verify transaction is recorded in history
  - Test error handling for insufficient balance

## Files to Edit
- backend/controllers/fastagController.js
- backend/routes/fastagRoutes.js

## Expected Outcome
- New API endpoint for toll payments
- User's wallet balance is deducted on toll payment
- Transaction history includes toll payment records
- Proper error handling for insufficient funds
