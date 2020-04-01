#!/usr/bin/env node

// Server dependencies.
import http from 'http'
import app from './app'

// Create HTTP server.
const port = app.get('port')
const server = http.createServer(app)

// Event listener for HTTP server "error" event.
server.on('error', (error) => {
  if (error.syscall !== 'listen') {
    throw error
  }

  // Handle specific listen errors with friendly messages
  switch (error.code) {
    case 'EACCES':
      log.error(error.port + ' requires elevated privileges')
      process.exit(1)
    case 'EADDRINUSE':
      log.error(error.port + ' is already in use')
      process.exit(1)
    default:
      throw error
  }
})

// Event listener for HTTP server "listening" event.
server.on('listening', () => {
  const addr = server.address()
  const bind = typeof addr === 'string'
    ? 'pipe ' + addr
    : 'port ' + addr.port

    console.log('Listening on ' + bind)
})
server.listen(port);

