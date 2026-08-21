<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\File;

class CreateStorageLink extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'storage:link-hosting';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Create storage symlink for hosting environment';

    /**
     * Execute the console command.
     *
     * @return int
     */
    public function handle()
    {
        $this->info('Creating storage symlink for hosting...');

        $target = storage_path('app/public');
        $link = public_path('storage');

        // Check if target directory exists
        if (!File::exists($target)) {
            $this->error('Storage directory does not exist: ' . $target);
            return 1;
        }

        // Remove existing link if it exists
        if (is_link($link)) {
            unlink($link);
            $this->info('Removed existing symlink');
        }

        // Remove existing directory if it exists
        if (File::exists($link) && is_dir($link)) {
            File::deleteDirectory($link);
            $this->info('Removed existing directory');
        }

        // Create symlink
        if (symlink($target, $link)) {
            $this->info('Storage symlink created successfully!');
            $this->info('Target: ' . $target);
            $this->info('Link: ' . $link);
            
            // Create .htaccess for storage access
            $this->createStorageHtaccess();
            
            return 0;
        } else {
            $this->error('Failed to create symlink. Trying alternative method...');
            
            // Alternative method: copy directory structure
            return $this->createStorageCopy();
        }
    }

    /**
     * Create .htaccess file for storage access
     */
    private function createStorageHtaccess()
    {
        $htaccessPath = public_path('storage/.htaccess');
        $htaccessContent = "Options -Indexes\n";
        $htaccessContent .= "<IfModule mod_rewrite.c>\n";
        $htaccessContent .= "    RewriteEngine On\n";
        $htaccessContent .= "    RewriteCond %{REQUEST_FILENAME} !-f\n";
        $htaccessContent .= "    RewriteCond %{REQUEST_FILENAME} !-d\n";
        $htaccessContent .= "    RewriteRule ^(.*)$ /index.php [L]\n";
        $htaccessContent .= "</IfModule>\n";

        if (File::put($htaccessPath, $htaccessContent)) {
            $this->info('Storage .htaccess created successfully!');
        } else {
            $this->warn('Failed to create storage .htaccess');
        }
    }

    /**
     * Alternative method: copy storage files instead of symlink
     */
    private function createStorageCopy()
    {
        $this->info('Creating storage copy instead of symlink...');
        
        $source = storage_path('app/public');
        $destination = public_path('storage');

        if (!File::exists($source)) {
            $this->error('Source directory does not exist: ' . $source);
            return 1;
        }

        // Create destination directory
        if (!File::exists($destination)) {
            File::makeDirectory($destination, 0755, true);
        }

        // Copy files recursively
        $this->copyDirectory($source, $destination);
        
        $this->info('Storage files copied successfully!');
        $this->createStorageHtaccess();
        
        return 0;
    }

    /**
     * Copy directory recursively
     */
    private function copyDirectory($source, $destination)
    {
        if (!File::exists($destination)) {
            File::makeDirectory($destination, 0755, true);
        }

        $files = File::files($source);
        foreach ($files as $file) {
            $targetFile = $destination . '/' . $file->getFilename();
            File::copy($file->getPathname(), $targetFile);
        }

        $directories = File::directories($source);
        foreach ($directories as $directory) {
            $targetDir = $destination . '/' . basename($directory);
            $this->copyDirectory($directory, $targetDir);
        }
    }
}
