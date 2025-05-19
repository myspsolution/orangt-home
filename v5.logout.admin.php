<?php
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

  // Redirect to the relative path
  header("Location: /id/v5/auth/sign-in");
  exit();
?>
