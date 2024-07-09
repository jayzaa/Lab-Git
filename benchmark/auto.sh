#!/bin/bash
sudo apt update -y;
sudo apt upgrade -y;
sudo apt install -y apt-transport-https lsb-release ca-certificates wget curl wrk;
#Add PHP8 Repo
wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg;
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list ;
#Add NodeJS Repo
curl -fsSL https://deb.nodesource.com/setup_22.x -o nodesource_setup.sh
sh nodesource_setup.sh
sudo apt install -y nodejs npm;
#War-Drama Folder
mkdir /tmp/server-test;
cd /tmp/server-test;
npm init -y
#Create server.js with the provided code
cat << 'EOF' > /tmp/server-test/server.js
const net = require('net');

const server = net.createServer((socket) => {
    socket.setNoDelay(true);
    socket.on('data', (data) => {
        // Simulate reading the request
        const request = data.toString();

        // Prepare the HTTP response
        const response = `HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\nHello, world!`;

        // Write the response to the client
        socket.write(response, () => {
            // Close the socket after the response has been sent
            socket.end();
        });
    });

    socket.on('error', (err) => {
        console.error('Socket error:', err);
    });
});

server.on('error', (err) => {
    console.error('Server error:', err);
});

server.listen(8080, () => {
    console.log('Server is listening on port 8080');
});
EOF

# Prep PHP8 
sudo apt update -y;
sudo apt install php php-cli php-mbstring php-curl unzip curl -y;
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer;
export COMPOSER_ALLOW_SUPERUSER=1
composer require phasync/server;


#Place Script
# Create server.php with the provided content
cat << 'EOF' > /tmp/server-test/server.php
<?php

echo "Starting server...\n";

// Check if JIT is enabled
if (ini_get('opcache.enable') && ini_get('opcache.jit_buffer_size')) {
    echo "JIT is enabled.\n";
} else {
    echo "JIT is not enabled.\n";
}

$context = stream_context_create([
    'socket' => [
        'backlog' => 511,
        'tcp_nodelay' => true,
    ]
]);

$socket = stream_socket_server('tcp://0.0.0.0:8081', $errno, $errstr, STREAM_SERVER_BIND | STREAM_SERVER_LISTEN, $context);
if (!$socket) {
    die("Could not create socket: $errstr ($errno)\n");
}
stream_set_chunk_size($socket, 65536);

echo "Server is running and listening on port 8081...\n";

while (true) {
    echo "Waiting for a connection...\n";
    $client = @stream_socket_accept($socket, -1);
    if ($client) {
        echo "Client connected...\n";
        $request = fread($client, 32768);
        echo "Received request:\n$request\n";
        fwrite($client, "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\nHello, world!");
        echo "Response sent to client.\n";
        fclose($client);
        echo "Client disconnected.\n";
    }
}
EOF
cat << 'EOF' > /tmp/server-test/server-async.php
<?php
require __DIR__ . '/vendor/autoload.php';

phasync::run(function () {
    $context = stream_context_create([
        'socket' => [
            'backlog' => 511,
            'tcp_nodelay' => true,
        ]
    ]);
    $socket = stream_socket_server('tcp://0.0.0.0:8082', $errno, $errstr, STREAM_SERVER_BIND | STREAM_SERVER_LISTEN, $context);
    if (!$socket) {
        die("Could not create socket: $errstr ($errno)");
    }
    stream_set_chunk_size($socket, 65536);
    while (true) {        
        phasync::readable($socket);     // Wait for activity on the server socket, while allowing coroutines to run
        if (!($client = stream_socket_accept($socket, 0))) {
            break;
        }
        
        phasync::go(function () use ($client) {
            //phasync::sleep();           // this single sleep allows the server to accept slightly more connections before reading and writing
            phasync::readable($client); // pause coroutine until resource is readable
            $request = \fread($client, 32768);
            phasync::writable($client); // pause coroutine until resource is writable
            $written = fwrite($client,
                "HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Type: text/plain\r\nContent-Length: 13\r\n\r\n".
                "Hello, world!"
            );
            fclose($client);
        });
    }
});
EOF
php /tmp/server-test/server.php & node server.js & php /tmp/server-test/server-async.php;