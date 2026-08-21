<?php

/**
 * Storage Symlink Cron Job Script
 * Run this script via cron job to ensure storage symlink exists
 * 
 * Usage in crontab:
 * 0,5,10,15,20,25,30,35,40,45,50,55 * * * * php /path/to/your/laravel/cron_storage.php
 */

// Set error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Define paths
$laravelPath = __DIR__;
$storagePath = $laravelPath . '/storage/app/public';
$publicStoragePath = $laravelPath . '/public/storage';

// Alternative paths for different hosting structures
if (!is_dir($storagePath)) {
    $storagePath = '/files/public_html/storage/app/public';
    $publicStoragePath = '/files/public_html/public/storage';
}

echo "Starting storage symlink check at " . date('Y-m-d H:i:s') . "\n";

// Check if storage directory exists
if (!is_dir($storagePath)) {
    echo "Storage directory does not exist: $storagePath\n";
    exit(1);
}

// Remove existing symlink if it exists
if (is_link($publicStoragePath)) {
    unlink($publicStoragePath);
    echo "Removed existing symlink\n";
}

// Remove existing directory if it exists
if (is_dir($publicStoragePath)) {
    rmdir($publicStoragePath);
    echo "Removed existing directory\n";
}

// Try to create symlink
if (symlink($storagePath, $publicStoragePath)) {
    echo "Symlink created successfully!\n";
} else {
    echo "Symlink failed, copying files instead...\n";
    
    // Create public/storage directory
    if (!is_dir($publicStoragePath)) {
        mkdir($publicStoragePath, 0755, true);
    }
    
    // Copy files recursively
    copyDirectory($storagePath, $publicStoragePath);
    echo "Files copied successfully!\n";
}

// Create .htaccess for storage
$htaccessContent = "Options -Indexes\n";
$htaccessContent .= "<IfModule mod_rewrite.c>\n";
$htaccessContent .= "    RewriteEngine On\n";
$htaccessContent .= "    RewriteCond %{REQUEST_FILENAME} !-f\n";
$htaccessContent .= "    RewriteCond %{REQUEST_FILENAME} !-d\n";
$htaccessContent .= "    RewriteRule ^(.*)$ /index.php [L]\n";
$htaccessContent .= "</IfModule>\n";

file_put_contents($publicStoragePath . '/.htaccess', $htaccessContent);
echo ".htaccess created for storage\n";

echo "Storage setup completed at " . date('Y-m-d H:i:s') . "\n";

/**
 * Copy directory recursively
 */
function copyDirectory($source, $destination) {
    if (!is_dir($destination)) {
        mkdir($destination, 0755, true);
    }
    
    $files = scandir($source);
    foreach ($files as $file) {
        if ($file != '.' && $file != '..') {
            $sourceFile = $source . '/' . $file;
            $destFile = $destination . '/' . $file;
            
            if (is_dir($sourceFile)) {
                copyDirectory($sourceFile, $destFile);
            } else {
                copy($sourceFile, $destFile);
                chmod($destFile, 0644);
            }
        }
    }
}
