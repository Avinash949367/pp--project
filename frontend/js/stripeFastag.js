// stripeFastag.js
// This script handles Stripe payment flow for FASTag recharge using Stripe Elements and UPI payment method.

document.addEventListener('DOMContentLoaded', () => {
  const stripePublishableKey = 'pk_test_51SFDB5B1XXAlO12Bu8FSHkMVqQRlt88kKmYq7wQ5QzWYpSlctLUvZswFk2NuIFVEOpOt2SrsQfQVjigMxxWVz9Ua00Z6WTOujC';
  const stripe = Stripe(stripePublishableKey);
  let elements;
  let paymentElement;
  const form = document.getElementById('rechargeForm');
  const paymentElementContainer = document.getElementById('payment-element');
  const rechargeBtn = document.getElementById('rechargeBtn');
  const loadingSpinner = document.getElementById('loadingSpinner');
  const selectedAmountInput = document.getElementById('selectedAmount');
  const vehicleNumberInput = document.getElementById('vehicleNumber');
  const fastagIdInput = document.getElementById('fastagId');

  // Initialize Stripe Elements
  async function initialize(clientSecret) {
    elements = stripe.elements({ clientSecret });
    paymentElement = elements.create('payment');
    paymentElement.mount(paymentElementContainer);
  }

  // Clear previous payment element if any
  function clearPaymentElement() {
    if (paymentElement) {
      paymentElement.unmount();
      paymentElement = null;
    }
  }

  // Handle form submission
  form.addEventListener('submit', async (e) => {
    e.preventDefault();

    const vehicleNumber = vehicleNumberInput.value.trim();
    const fastagId = fastagIdInput.value.trim();
    const amount = selectedAmountInput.value;
    const upiId = document.getElementById('upiId').value.trim();

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
    if (!upiId) {
      alert('Please enter your UPI ID.');
      return;
    }

    // Basic UPI ID validation
    const upiPattern = /^[^\s@]+@[^\s@]+$/;
    if (!upiPattern.test(upiId)) {
      alert('Please enter a valid UPI ID (e.g., user@paytm).');
      return;
    }

    // Get authentication token
    const token = localStorage.getItem('token');
    if (!token) {
      alert('You must be logged in to recharge your FASTag.');
      return;
    }

    rechargeBtn.disabled = true;
    loadingSpinner.classList.remove('hidden');

    try {
      // Create PaymentIntent on backend
      const response = await fetch('http://localhost:5000/api/fastag/recharge', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token
        },
        body: JSON.stringify({
          amount: Number(amount),
          vehicleNumber: vehicleNumber,
          paymentMethod: 'upi',
          upiId: upiId
        })
      });

      const data = await response.json();

      if (!response.ok) {
        alert(data.message || 'Failed to create payment intent.');
        rechargeBtn.disabled = false;
        loadingSpinner.classList.add('hidden');
        return;
      }

      // Check if Stripe PaymentIntent was created (for card payments)
      if (data.clientSecret) {
        // Initialize Stripe Elements with client secret
        clearPaymentElement();
        await initialize(data.clientSecret);

        // Confirm payment on submit
        const { error } = await stripe.confirmPayment({
          elements,
          confirmParams: {
            return_url: window.location.href, // Redirect back to current page after payment
          },
        });

        if (error) {
          alert(error.message);
          rechargeBtn.disabled = false;
          loadingSpinner.classList.add('hidden');
        } else {
          alert('Payment successful! Your FASTag wallet has been recharged.');
          rechargeBtn.disabled = false;
          loadingSpinner.classList.add('hidden');
          form.reset();
          clearPaymentElement();
        }
      } else if (data.upiDeepLink) {
        // Handle manual UPI flow
        alert('UPI payment initiated. Complete the payment using your UPI app.');

        // Show QR code modal or redirect to UPI app
        showUpiPaymentModal(data);

        rechargeBtn.disabled = false;
        loadingSpinner.classList.add('hidden');
      }
    } catch (err) {
      console.error('Error during payment:', err);
      alert('An error occurred during payment. Please try again.');
      rechargeBtn.disabled = false;
      loadingSpinner.classList.add('hidden');
    }
  });

  // Amount selection buttons logic
  const amountButtons = document.querySelectorAll('.amount-option');
  const customAmountBtn = document.getElementById('customAmountBtn');
  const customAmountContainer = document.getElementById('customAmountContainer');
  const customAmountInput = document.getElementById('customAmount');

  amountButtons.forEach(button => {
    button.addEventListener('click', () => {
      amountButtons.forEach(btn => btn.classList.remove('bg-blue-600', 'text-white'));
      button.classList.add('bg-blue-600', 'text-white');
      selectedAmountInput.value = button.dataset.amount;
      customAmountContainer.classList.add('hidden');
      customAmountInput.value = '';
    });
  });

  customAmountBtn.addEventListener('click', () => {
    amountButtons.forEach(btn => btn.classList.remove('bg-blue-600', 'text-white'));
    customAmountContainer.classList.remove('hidden');
    selectedAmountInput.value = '';
  });

  customAmountInput.addEventListener('input', () => {
    selectedAmountInput.value = customAmountInput.value;
  });

  // Function to show UPI payment modal
  function showUpiPaymentModal(data) {
    // Create modal HTML
    const modalHtml = `
      <div id="upiModal" class="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50">
        <div class="relative top-20 mx-auto p-5 border w-96 shadow-lg rounded-md bg-white">
          <div class="mt-3 text-center">
            <h3 class="text-lg font-medium text-gray-900">Complete UPI Payment</h3>
            <div class="mt-2 px-7 py-3">
              <p class="text-sm text-gray-500">
                Scan the QR code or click "Open UPI App" to complete your payment of ₹${data.amount}
              </p>
              <div class="mt-4">
                <img src="${data.qrCodeUrl}" alt="UPI QR Code" class="mx-auto w-48 h-48">
              </div>
              <div class="mt-4">
                <a href="${data.upiDeepLink}" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded mr-2" target="_blank">
                  Open UPI App
                </a>
                <button id="confirmPaymentBtn" class="bg-green-500 hover:bg-green-700 text-white font-bold py-2 px-4 rounded">
                  Confirm Payment
                </button>
              </div>
            </div>
            <div class="flex items-center px-4 py-3">
              <button id="closeUpiModal" class="px-4 py-2 bg-gray-500 text-white text-base font-medium rounded-md w-full shadow-sm hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-300">
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
    `;

    // Add modal to body
    document.body.insertAdjacentHTML('beforeend', modalHtml);

    // Add event listeners
    document.getElementById('closeUpiModal').addEventListener('click', () => {
      document.getElementById('upiModal').remove();
    });

    document.getElementById('confirmPaymentBtn').addEventListener('click', async () => {
      try {
        const token = localStorage.getItem('token');
        const response = await fetch('http://localhost:5000/api/fastag/confirm-upi', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ' + token
          },
          body: JSON.stringify({
            transactionId: data.transactionId
          })
        });

        const result = await response.json();

        if (response.ok) {
          alert('Payment confirmed successfully! Your FASTag wallet has been recharged.');
          document.getElementById('upiModal').remove();
          form.reset();
          // Optionally refresh balance
          location.reload();
        } else {
          alert(result.message || 'Failed to confirm payment');
        }
      } catch (err) {
        console.error('Error confirming payment:', err);
        alert('Error confirming payment. Please try again.');
      }
    });
  }
});
