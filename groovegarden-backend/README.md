http://localhost:8081/oauth/login

icecast -c /usr/local/etc/icecast.xml

curl -X POST http://localhost:8081/stream/start
curl -X POST http://localhost:8081/stream/stop