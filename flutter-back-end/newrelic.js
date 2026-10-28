'use strict'

// License key comes from NEW_RELIC_LICENSE_KEY. For an EU account also set
// NEW_RELIC_HOST=collector.eu01.nr-data.net
exports.config = {
  app_name: ['flutter-back-end'],
  distributed_tracing: { enabled: true },
  application_logging: {
    enabled: true,
    forwarding: { enabled: true },
    local_decorating: { enabled: true }
  },
  logging: { level: 'info' }
}
