FROM nginx:alpine

# Copy HTML files from html directory
COPY html/*.html /usr/share/nginx/html/

# Copy JavaScript files from js directory
COPY js/*.js /usr/share/nginx/html/js/

# Copy test data JSON files from test_data directory
COPY test_data/*.json /usr/share/nginx/html/test_data/

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
