const http = require('http');
const port = 3000;

const requestHandler = (req, res) => {
	res.end('Welcome To My learning journey');
};

const server = http.createServer(requestHandler);

server.listen(port, () => {
	console.log('server running on port ${port}');
});

