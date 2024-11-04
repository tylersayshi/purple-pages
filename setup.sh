#!/bin/bash

source ~/.profile

sudo apt update && sudo apt upgrade -y

# Install Nginx
sudo apt install nginx -y

# Remove old Nginx config (if it exists)
sudo rm -f /etc/nginx/sites-available/purple-pages
sudo rm -f /etc/nginx/sites-enabled/purple-pages

# Stop Nginx temporarily to allow Certbot to run in standalone mode
sudo systemctl stop nginx

# Obtain SSL certificate using Certbot standalone mode
sudo apt install certbot -y
sudo certbot certonly --standalone -d sprt.dev --non-interactive --agree-tos -m $EMAIL

sudo cat > /etc/nginx/sites-available/purple-pages <<EOL
limit_req_zone \$binary_remote_addr zone=mylimit:10m rate=10r/s;
server {
    listen 80;
    server_name sprt.dev;

    # Redirect all HTTP requests to HTTPS when is not curl
    if (\$http_user_agent !~* curl) {
        return 301 https://\$host\$request_uri;
    }
    
    location / {
        limit_req zone=mylimit burst=20 nodelay;
        
        proxy_pass http://localhost:7778; 
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

sudo ln -s /etc/nginx/sites-available/purple-pages /etc/nginx/sites-enabled/purple-pages

# Restart Nginx to apply the new configuration
sudo systemctl restart nginx

echo "Done!"
