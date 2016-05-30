var net = require('net');

var server = net.createServer(function(socket) {
    socket.on('data', function (data) {
        console.log(data);
    })
});

server.listen(5577, '127.0.0.1');