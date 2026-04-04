// ============================================
// COPY-PASTE TEMPLATES FOR NESTJS INTEGRATION
// ============================================

// File: src/observability/prometheus.middleware.ts
// Purpose: Collect HTTP metrics (requests, latency, memory)

import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';
import * as promClient from 'prom-client';
import { v4 as uuidv4 } from 'uuid';

// ===== METRICS DEFINITIONS =====
export const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests by method, route, and status code',
  labelNames: ['method', 'route', 'status_code'],
});

export const httpRequestDurationSeconds = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.1, 0.5, 1.0, 2.0, 5.0, 10.0],
});

export const processResidentMemoryBytes = new promClient.Gauge({
  name: 'process_resident_memory_bytes',
  help: 'Resident memory in bytes',
  collect() {
    const memUsage = process.memoryUsage();
    this.set(memUsage.rss);
  },
});

export const processHeapUsedBytes = new promClient.Gauge({
  name: 'process_heap_used_bytes',
  help: 'Heap memory used in bytes',
  collect() {
    const memUsage = process.memoryUsage();
    this.set(memUsage.heapUsed);
  },
});

export const databaseConnectionPoolSize = new promClient.Gauge({
  name: 'db_connection_pool_size',
  help: 'Number of active database connections',
  labelNames: ['pool_name'],
});

// ===== REQUEST ID MIDDLEWARE =====
@Injectable()
export class RequestIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const requestId = (req.headers['x-request-id'] as string) || uuidv4();
    req['requestId'] = requestId;
    
    // Echo request ID in response headers
    res.setHeader('x-request-id', requestId);
    res.setHeader('x-response-time', new Date().toISOString());
    
    // Attach to logger context
    if (req['logger']) {
      req['logger'] = req['logger'].child({ requestId });
    }
    
    next();
  }
}

// ===== METRICS MIDDLEWARE =====
@Injectable()
export class PrometheusMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const start = Date.now();
    const originalSend = res.send;

    res.send = function (data) {
      const duration = (Date.now() - start) / 1000;
      const statusCode = res.statusCode;
      const routePath = req.route?.path || req.path;
      const method = req.method;

      // Record metrics
      httpRequestsTotal.inc({
        method,
        route: routePath,
        status_code: statusCode,
      });

      httpRequestDurationSeconds.observe(
        {
          method,
          route: routePath,
          status_code: statusCode,
        },
        duration,
      );

      // Log request completion with request ID
      const requestId = req['requestId'];
      console.log(
        `[${requestId}] ${method} ${routePath} - ${statusCode} (${(duration * 1000).toFixed(2)}ms)`,
      );

      res.send = originalSend;
      return res.send(data);
    };

    next();
  }
}

// ============================================
// File: src/observability/logger.service.ts
// Purpose: Structured logging with requestId
// ============================================

import { Injectable, Inject } from '@nestjs/common';
import { REQUEST } from '@nestjs/core';
import { Request } from 'express';
import * as winston from 'winston';

@Injectable()
export class LoggerService {
  private logger: winston.Logger;

  constructor(@Inject(REQUEST) private request: Request) {
    this.logger = winston.createLogger({
      level: process.env.LOG_LEVEL || 'info',
      format: winston.format.combine(
        winston.format.timestamp(),
        winston.format.errors({ stack: true }),
        winston.format.json(),
      ),
      defaultMeta: {
        service: 'nestjs-backend',
        environment: process.env.NODE_ENV || 'development',
      },
      transports: [
        new winston.transports.Console({
          format: winston.format.combine(
            winston.format.colorize(),
            winston.format.simple(),
          ),
        }),
        // Optional: Send to file or external service (Loki, Sentry)
      ],
    });
  }

  private getMeta() {
    const requestId = this.request?.['requestId'];
    return requestId ? { requestId } : {};
  }

  log(message: string, meta?: any) {
    this.logger.info(message, { ...this.getMeta(), ...meta });
  }

  error(message: string, error?: Error, meta?: any) {
    this.logger.error(message, {
      ...this.getMeta(),
      ...meta,
      error: {
        message: error?.message,
        stack: error?.stack,
      },
    });
  }

  warn(message: string, meta?: any) {
    this.logger.warn(message, { ...this.getMeta(), ...meta });
  }

  debug(message: string, meta?: any) {
    this.logger.debug(message, { ...this.getMeta(), ...meta });
  }
}

// ============================================
// File: src/app.module.ts
// Purpose: Register all middlewares
// ============================================

import { Module, MiddlewareConsumer, NestModule } from '@nestjs/common';
import { RequestIdMiddleware } from './observability/prometheus.middleware';
import { PrometheusMiddleware } from './observability/prometheus.middleware';

@Module({
  // ... other config
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(RequestIdMiddleware)
      .forRoutes('*')
      .apply(PrometheusMiddleware)
      .forRoutes('*');
  }
}

// ============================================
// File: src/main.ts
// Purpose: Expose /metrics endpoint & start app
// ============================================

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { register } from 'prom-client';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Expose Prometheus metrics endpoint
  // Prometheus will scrape: GET http://localhost:3001/metrics
  app.get('/metrics', (req, res) => {
    try {
      res.set('Content-Type', register.contentType);
      res.end(register.metrics());
    } catch (err) {
      res.status(500).end(err);
    }
  });

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      memory: process.memoryUsage(),
    });
  });

  const port = process.env.PORT || 3001;
  await app.listen(port);
  console.log(`🚀 Backend running on http://localhost:${port}`);
  console.log(`📊 Metrics available at http://localhost:${port}/metrics`);
  console.log(`❤️  Health check at http://localhost:${port}/health`);
}

bootstrap();

// ============================================
// File: src/database/database.service.ts
// Purpose: Track database connection pool
// ============================================

import { Injectable } from '@nestjs/common';
import { DataSource } from 'typeorm';
import { databaseConnectionPoolSize } from './observability/prometheus.middleware';

@Injectable()
export class DatabaseService {
  constructor(private dataSource: DataSource) {
    this.trackConnectionPool();
  }

  private trackConnectionPool() {
    setInterval(() => {
      try {
        const poolSize = this.dataSource.driver.pool?.activeConnections?.length || 0;
        databaseConnectionPoolSize.set({ pool_name: 'postgres' }, poolSize);
      } catch (err) {
        console.warn('Failed to update DB connection pool metric:', err);
      }
    }, 30000); // Update every 30 seconds
  }

  async query(sql: string, params?: any[]) {
    return this.dataSource.query(sql, params);
  }
}

// ============================================
// File: package.json (dependencies to add)
// ============================================

/*
{
  "dependencies": {
    "prom-client": "^15.0.0",
    "winston": "^3.10.0"
  }
}

Install:
npm install prom-client winston
*/

// ============================================
// USAGE EXAMPLES
// ============================================

/*
// In any controller/service:

import { LoggerService } from './observability/logger.service';

@Controller('api')
export class MyController {
  constructor(private logger: LoggerService) {}

  @Get('data')
  getData() {
    this.logger.log('Fetching data', { action: 'getData' });
    
    try {
      // ... your logic
      this.logger.log('Data fetched successfully', { count: 42 });
    } catch (error) {
      this.logger.error('Failed to fetch data', error, { action: 'getData' });
    }
  }
}

// ============================================
// PROMETHEUS QUERIES (Use in Grafana)
// ============================================

// Error rate (5-minute window)
rate(http_requests_total{status=~"5.."}[5m])

// P95 latency
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) * 1000

// Memory usage
process_resident_memory_bytes / (1024 * 1024 * 1024)

// Request rate by endpoint
rate(http_requests_total[1m]) by (route)

// Database connection pool usage
db_connection_pool_size
*/
