#!/bin/bash

# Storage Symlink Script for Laravel Hosting
# This script creates storage symlink for Laravel applications

# Set the path to your Laravel application
LARAVEL_PATH="/home/username/public_html"
# Change 'username' to your actual Hostinger username

# Navigate to Laravel directory
cd $LARAVEL_PATH

# Create storage symlink using artisan command
php artisan storage:link-hosting

# Alternative method if symlink fails
if [ $? -ne 0 ]; then
    echo "Symlink failed, trying manual method..."
    
    # Create storage directory in public if it doesn't exist
    mkdir -p public/storage
    
    # Copy files from storage/app/public to public/storage
    cp -r storage/app/public/* public/storage/ 2>/dev/null || echo "No files to copy"
    
    # Set proper permissions
    chmod -R 755 public/storage
    chmod -R 644 public/storage/* 2>/dev/null || echo "No files to set permissions"
    
    echo "Storage files copied manually"
fi

# Create .htaccess for storage access
cat > public/storage/.htaccess << 'EOF'
Options -Indexes
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule ^(.*)$ /index.php [L]
</IfModule>
EOF

echo "Storage setup completed at $(date)"
