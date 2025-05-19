<?php
function isFromBackendLogin() {
    if (empty($_SERVER['HTTP_REFERER'])) {
        return false;
    }

    // Parse the referer URL
    $referer = parse_url($_SERVER['HTTP_REFERER']);

    // Ensure 'host' and 'path' are both present and not empty
    if (empty($referer['host']) || empty($referer['path'])) {
        return false;
    }

    // Get the current domain
    $currentDomain = $_SERVER['HTTP_HOST'];

    // Check if the referer is from the same domain and ends with "v5/auth/sign-in"
    $expectedPath = 'v5/auth/sign-in';
    if (
        $referer['host'] !== $currentDomain ||
        substr($referer['path'], -strlen($expectedPath)) !== $expectedPath
    ) {
        return false;
    }

    // Check if required cookies exist
    if (empty($_COOKIE['XSRF-TOKEN']) || empty($_COOKIE['laravel_session'])) {
        return false;
    }

    return true;
}

function resetAllCookies() {
    foreach ($_COOKIE as $name => $value) {
        setcookie($name, "", time() - 3600, "/");
    }
}

$refererValid = isFromBackendLogin();

if ($refererValid) {
    header("Location: /id/v5/manage/dashboard/learning");
    exit();
} else {
    resetAllCookies();
    header("Location: /fe/login");
    exit();
}
?>
