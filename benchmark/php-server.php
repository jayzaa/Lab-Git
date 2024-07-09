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