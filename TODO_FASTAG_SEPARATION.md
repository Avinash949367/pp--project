# FASTag Page Separation Task

## Overview
Divide FASTag functionality into two separate pages:
- One for FASTag ID generation (get-fastag.html)
- One for FASTag payment/recharge (fastag.html)
- Link them based on whether user has FASTag ID

## Steps
- [ ] Modify frontend/get-fastag.html to focus only on FASTag ID generation/application
- [ ] Modify frontend/fastag.html to focus only on FASTag recharge/payment
- [ ] Add navigation logic in frontend to check user profile for FASTag ID and redirect accordingly
- [ ] Test the flow: ID generation -> redirect to recharge; existing ID -> direct to recharge

## Files to Edit
- frontend/get-fastag.html
- frontend/fastag.html
- frontend/js/auth.js (add profile check and navigation logic)

## Backend
- No changes needed, use existing /profile endpoint to check fastagId
