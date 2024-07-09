Standalone Server Test for PHP and Node.js

This is a test standalone server for PHP and Node.js.

How to Run

To start both servers, use the auto.sh script
sudo bash auto.sh

Server Details

	•	Node.js: Listens on port 8080
	•	PHP: Listens on port 8081
    •	PHP: Code async Listens on port 8082

Testing with wrk

You can test the performance using wrk. The following example tests the Node.js server:

wrk -t4 -c1600 -d5s http://127.0.0.1:8080/

Explanation

	•	-t4: Uses 4 threads.
	•	-c1600: Maintains 1600 open connections.
	•	-d5s: Runs the test for 5 seconds.

Note

You can change 127.0.0.1 to your preferred IP address.

Purpose

The wrk test is for benchmarking the server’s performance, focusing on the number of requests per second (requests/sec). It provides a high-level overview of how many requests the server can handle under load.

Focus

While the test can provide various metrics, the primary focus should be on requests per second (requests/sec) to evaluate the server’s handling capacity.

