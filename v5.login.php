<?php
  // Start session
  session_start();

  // Function to reset all cookies
  function resetAllCookies() {
    // Loop through each cookie
    foreach ($_COOKIE as $name => $value) {
      // Unset the cookie by setting its expiration time in the past
      setcookie($name, "", time() - 3600, "/");
    }
  }

  // Reset all cookies
  resetAllCookies();

  // Unset all session variables
  $_SESSION = array();

  // Destroy the session
  session_destroy();

  // Redirect to the relative path
  header("Location: /fe/login");
  exit();
?>
