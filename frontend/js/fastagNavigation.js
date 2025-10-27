// Function to check if user has FASTag ID and redirect accordingly
async function checkFastagAccess() {
  const token = localStorage.getItem('token');
  if (!token) {
    // User not logged in, redirect to login
    window.location.href = 'userlogin.html';
    return;
  }

  try {
    const response = await fetch('http://localhost:5000/profile', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      // Token invalid or expired, redirect to login
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = 'userlogin.html';
      return;
    }

    const userData = await response.json();

    if (!userData.fastagId) {
      // User doesn't have FASTag ID, redirect to get-fastag.html
      window.location.href = 'get-fastag.html';
    }
    // If user has fastagId, allow access to fastag.html
  } catch (error) {
    console.error('Error checking FASTag access:', error);
    // On error, redirect to login
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = 'userlogin.html';
  }
}

// Function to check if user needs to get FASTag ID
async function checkFastagId() {
  const token = localStorage.getItem('token');
  if (!token) {
    // User not logged in, redirect to login
    window.location.href = 'userlogin.html';
    return;
  }

  try {
    const response = await fetch('http://localhost:5000/profile', {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      // Token invalid or expired, redirect to login
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = 'userlogin.html';
      return;
    }

    const userData = await response.json();

    if (userData.fastagId) {
      // User already has FASTag ID, redirect to fastag.html
      window.location.href = 'fastag.html';
    }
    // If user doesn't have fastagId, allow access to get-fastag.html
  } catch (error) {
    console.error('Error checking FASTag ID:', error);
    // On error, redirect to login
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = 'userlogin.html';
  }
}
