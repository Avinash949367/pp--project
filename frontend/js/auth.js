// Helper function to validate password complexity
function validatePassword(password) {
  const errors = [];
  
  // Check for at least one uppercase letter
  if (!/[A-Z]/.test(password)) {
    errors.push("uppercase letter");
  }
  
  // Check for at least one lowercase letter
  if (!/[a-z]/.test(password)) {
    errors.push("lowercase letter");
  }
  
  // Check for at least one number
  if (!/[0-9]/.test(password)) {
    errors.push("number");
  }
  
  // Check for at least one special character
  if (!/[!@#$%^&*(),.?":{}|<>]/.test(password)) {
    errors.push("special character");
  }
  
  return errors;
}

document.addEventListener('DOMContentLoaded', () => {
  const loginForm = document.getElementById('loginForm');
  const errorElem = document.getElementById('loginError');
  const showSignUpBtn = document.getElementById('showSignUp');
  const showLoginBtn = document.getElementById('showLogin');
  const signUpFormContainer = document.getElementById('signUpForm');
  const loginToggle = document.getElementById('loginToggle');
  const signUpToggle = document.getElementById('signUpToggle');
  const registerForm = document.getElementById('registerForm');
  const googleLoginBtn = document.getElementById('googleLogin');
  const otpVerificationForm = document.getElementById('otpVerificationForm');
  const otpForm = document.getElementById('otpForm');
  const otpErrorElem = document.getElementById('otpError');

  if (!loginForm) {
    console.error('Login form not found');
    return;
  }

  loginForm.addEventListener('submit', async function (e) {
    e.preventDefault();
    const email = document.getElementById('email').value.trim();
    const password = document.getElementById('password').value.trim();
    errorElem.classList.add('hidden');
    errorElem.textContent = '';

    // Email validation for @gmail.com
    if (!email.endsWith('@gmail.com')) {
      errorElem.textContent = 'Email must be a Gmail address (@gmail.com)';
      errorElem.classList.remove('hidden');
      return;
    }

    console.log('Submitting login for:', email);

    try {
      const response = await fetch('http://localhost:5000/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password }),
      });
      const data = await response.json();
      if (!response.ok) {
        console.error('Login failed:', data.message);
        errorElem.textContent = data.message || 'Login failed';
        errorElem.classList.remove('hidden');
      } else {
        console.log('Login successful:', data);
        localStorage.setItem('token', data.token);
        localStorage.setItem('user', JSON.stringify(data.user));
        localStorage.setItem('email', email);
        // Redirect only non-admin users to index.html
        if (data.user.role === 'admin') {
          errorElem.textContent = 'Admin users must login via the admin login page.';
          errorElem.classList.remove('hidden');
          // Optionally clear stored data
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          localStorage.removeItem('email');
        } else {
          localStorage.setItem('isLoggedIn', 'true');
          window.location.href = 'index.html';
        }
      }
    } catch (err) {
      console.error('Error during login:', err);
      errorElem.textContent = 'An error occurred during login.';
      errorElem.classList.remove('hidden');
    }
  });

  // Toggle sign-up form visibility
  showSignUpBtn.addEventListener('click', () => {
    signUpFormContainer.classList.remove('hidden');
    loginForm.classList.add('hidden');
    loginToggle.classList.add('hidden');
    signUpToggle.classList.remove('hidden');
    errorElem.classList.add('hidden');
    otpVerificationForm.classList.add('hidden');
    otpErrorElem.classList.add('hidden');
  });

  // Toggle login form visibility
  showLoginBtn.addEventListener('click', () => {
    signUpFormContainer.classList.add('hidden');
    loginForm.classList.remove('hidden');
    loginToggle.classList.remove('hidden');
    signUpToggle.classList.add('hidden');
    errorElem.classList.add('hidden');
    otpVerificationForm.classList.add('hidden');
    otpErrorElem.classList.add('hidden');
  });

  // Handle sign-up form submission
  registerForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const name = document.getElementById('name').value.trim();
    const email = document.getElementById('emailSignUp').value.trim();
    const password = document.getElementById('passwordSignUp').value.trim();
    const confirmPassword = document.getElementById('confirmPassword').value.trim();

    // Email validation for @gmail.com
    if (!email.endsWith('@gmail.com')) {
      alert('Email must be a Gmail address (@gmail.com) for registration');
      return;
    }

    // Name length validation
    if (name.length > 10) {
      alert('Name must not exceed 10 characters');
      return;
    }

    // Confirm password validation
    if (password !== confirmPassword) {
      alert('Passwords do not match. Please make sure both password fields are identical.');
      return;
    }

    // Client-side password validation
    const passwordErrors = validatePassword(password);
    if (passwordErrors.length > 0) {
      const errorMessage = `Password must contain at least one ${passwordErrors.join(', ')}`;
      alert(errorMessage);
      return;
    }

    try {
      const response = await fetch('http://localhost:5000/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, email, password }),
      });
      const data = await response.json();
      if (!response.ok) {
        alert(data.message || 'Sign up failed');
      } else {
        alert('Sign up successful! Please check your email for the OTP to verify your account.');
        signUpFormContainer.classList.add('hidden');
        otpVerificationForm.classList.remove('hidden');
        otpErrorElem.classList.add('hidden');
        // Store email for OTP verification
        otpVerificationForm.dataset.email = email;
      }
    } catch (err) {
      alert('An error occurred during sign up.');
      console.error('Sign up error:', err);
    }
  });

  // Handle OTP form submission
  otpForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    const otp = document.getElementById('otpInput').value.trim();
    const email = otpVerificationForm.dataset.email;
    otpErrorElem.classList.add('hidden');
    otpErrorElem.textContent = '';

    try {
      const response = await fetch('http://localhost:5000/api/auth/verify-otp', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, otp }),
      });
      const data = await response.json();
      if (!response.ok) {
        otpErrorElem.textContent = data.message || 'OTP verification failed';
        otpErrorElem.classList.remove('hidden');
      } else {
        alert('OTP verified successfully! You can now log in.');
        otpVerificationForm.classList.add('hidden');
        loginForm.classList.remove('hidden');
        loginToggle.classList.remove('hidden');
        signUpToggle.classList.add('hidden');
        otpErrorElem.classList.add('hidden');
      }
    } catch (err) {
      otpErrorElem.textContent = 'An error occurred during OTP verification.';
      otpErrorElem.classList.remove('hidden');
      console.error('OTP verification error:', err);
    }
  });

  // Handle Google login button click
  googleLoginBtn.addEventListener('click', () => {
    window.location.href = 'http://localhost:5000/auth/google';
  });
});