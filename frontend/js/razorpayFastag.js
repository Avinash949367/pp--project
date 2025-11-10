// razorpayFastag.js
// This script handles Razorpay payment flow for FASTag recharge.

document.addEventListener('DOMContentLoaded', () => {
  const razorpayBtn = document.getElementById('razorpayBtn');
  const rechargeBtn = document.getElementById('rechargeBtn');
  const loadingSpinner = document.getElementById('razorpayLoadingSpinner');
  const selectedAmountInput = document.getElementById('selectedAmount');
  const vehicleNumberInput = document.getElementById('vehicleNumber');
  const fastagIdInput = document.getElementById('fastagId');

  // Handle Razorpay button click
  razorpayBtn.addEventListener('click', async () => {
    const vehicleNumber = vehicleNumberInput.value.trim();
    const fastagId = fastagIdInput.value.trim();
    const amount = selectedAmountInput.value;

    if (!vehicleNumber) {
      alert('Please enter your vehicle number.');
      return;
    }
    if (!fastagId) {
      alert('Please enter your FASTag ID.');
      return;
    }
    if (!amount || isNaN(amount) || Number(amount) < 100) {
      alert('Please select or enter a valid recharge amount (minimum ₹100).');
      return;
    }

    // Get authentication token
    const token = localStorage.getItem('token');
    if (!token) {
      alert('You must be logged in to recharge your FASTag.');
      return;
    }

    razorpayBtn.disabled = true;
    loadingSpinner.classList.remove('hidden');

    try {
      // Create Razorpay order on backend
      const response = await fetch('http://localhost:5000/api/fastag/recharge', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token
        },
        body: JSON.stringify({
          amount: Number(amount),
          vehicleNumber: vehicleNumber,
          paymentMethod: 'razorpay'
        })
      });

      const data = await response.json();

      if (!response.ok) {
        alert(data.message || 'Failed to create payment order.');
        razorpayBtn.disabled = false;
        loadingSpinner.classList.add('hidden');
        return;
      }

      // Initialize Razorpay checkout
      const options = {
        key: data.key,
        amount: data.amount,
        currency: data.currency,
        order_id: data.orderId,
        name: 'ParkPro FASTag',
        description: 'FASTag Recharge',
        image: 'https://example.com/logo.png', // Replace with your logo URL
        handler: async function (response) {
          try {
            // Verify payment with backend
            const verifyResponse = await fetch('http://localhost:5000/api/fastag/verify-razorpay-payment', {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer ' + token
              },
              body: JSON.stringify({
                paymentId: response.razorpay_payment_id,
                orderId: response.razorpay_order_id
              })
            });

            const verifyData = await verifyResponse.json();

            if (verifyResponse.ok) {
              alert('Payment successful! Your FASTag wallet has been recharged.');
              // Optionally refresh balance or redirect
              location.reload();
            } else {
              alert('Payment verification failed: ' + verifyData.message);
            }
          } catch (error) {
            console.error('Error verifying payment:', error);
            alert('Payment completed but verification failed. Please contact support.');
          } finally {
            razorpayBtn.disabled = false;
            loadingSpinner.classList.add('hidden');
          }
        },
        prefill: {
          name: '', // You can get this from user profile
          email: '', // You can get this from user profile
          contact: '' // You can get this from user profile
        },
        notes: {
          address: 'ParkPro FASTag Recharge'
        },
        theme: {
          color: '#46949d'
        },
        modal: {
          ondismiss: function() {
            razorpayBtn.disabled = false;
            loadingSpinner.classList.add('hidden');
            alert('Payment cancelled by user.');
          }
        }
      };

      const rzp = new Razorpay(options);
      rzp.open();

    } catch (err) {
      console.error('Error during Razorpay payment:', err);
      alert('An error occurred during payment. Please try again.');
      razorpayBtn.disabled = false;
      loadingSpinner.classList.add('hidden');
    }
  });
});
