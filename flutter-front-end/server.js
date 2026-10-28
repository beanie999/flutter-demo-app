'use strict'
// The agent must be loaded before anything else.
const newrelic = require('newrelic')
const express = require('express')
const axios = require('axios')
const pino = require('pino')

const log = pino({ name: 'flutter-front-end' })
const app = express()
const PORT = process.env.PORT || 3001
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3002'

// Tag every transaction with the end user passed by the mobile app.
app.use((req, res, next) => {
  const username = req.get('x-username') || 'anonymous'
  req.username = username
  newrelic.addCustomAttribute('enduser.id', username)
  newrelic.addCustomAttribute('username', username)
  newrelic.setUserID(username)
  next()
})

app.get('/health', (req, res) => res.json({ status: 'ok' }))

app.get('/api/order', async (req, res) => {
  const orderId = req.query.orderId || `order-${Date.now()}`
  newrelic.addCustomAttribute('orderId', orderId)
  log.info({ username: req.username, orderId }, 'received order request')

  try {
    // The agent adds distributed tracing headers to this outgoing call.
    const { data } = await axios.get(`${BACKEND_URL}/process`, {
      params: { orderId },
      headers: { 'x-username': req.username },
      timeout: 5000
    })
    log.info({ username: req.username, orderId }, 'back-end call succeeded')
    res.json({ ok: true, orderId, backend: data })
  } catch (err) {
    const status = err.response?.status
    newrelic.noticeError(err, { username: req.username, orderId, backendStatus: status })
    log.error({ username: req.username, orderId, backendStatus: status, err: err.message }, 'back-end call failed')
    res.status(502).json({ ok: false, orderId, error: err.message, backendStatus: status })
  }
})

app.listen(PORT, () => log.info(`flutter-front-end listening on ${PORT}, back-end at ${BACKEND_URL}`))
