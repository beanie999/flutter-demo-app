'use strict'
// The agent must be loaded before anything else.
const newrelic = require('newrelic')
const express = require('express')
const pino = require('pino')

const log = pino({ name: 'flutter-back-end' })
const app = express()
const PORT = process.env.PORT || 3002
const ERROR_RATE = Number(process.env.ERROR_RATE || 0.25)

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

// Tag every transaction with the end user passed down from the mobile app.
app.use((req, res, next) => {
  const username = req.get('x-username') || 'anonymous'
  req.username = username
  newrelic.addCustomAttribute('enduser.id', username)
  newrelic.addCustomAttribute('username', username)
  newrelic.setUserID(username)
  next()
})

app.get('/health', (req, res) => res.json({ status: 'ok' }))

app.get('/process', async (req, res) => {
  const orderId = req.query.orderId || 'unknown'
  newrelic.addCustomAttribute('orderId', orderId)
  log.info({ username: req.username, orderId }, 'processing request')

  // Simulate work, with the occasional slow call.
  await newrelic.startSegment('simulate-work', true, () =>
    sleep(50 + Math.random() * (Math.random() < 0.2 ? 1500 : 300))
  )

  if (Math.random() < ERROR_RATE) {
    const err = new Error(`Back-end failed processing order ${orderId}`)
    newrelic.noticeError(err, { username: req.username, orderId })
    log.error({ username: req.username, orderId, err: err.message }, 'processing failed')
    return res.status(500).json({ error: err.message })
  }

  log.info({ username: req.username, orderId }, 'processing succeeded')
  res.json({ status: 'processed', orderId, processedFor: req.username })
})

app.listen(PORT, () => log.info(`flutter-back-end listening on ${PORT} (error rate ${ERROR_RATE})`))
