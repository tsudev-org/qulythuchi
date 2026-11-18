declare namespace Cloudflare {
  interface Env {
    DB: D1Database;
    FILES: R2Bucket;
    TEST_MIGRATIONS: import('cloudflare:test').D1Migration[];
    PUBLIC_ORIGIN: string;
    OIDC_ISSUER: string;
    OIDC_CLIENT_ID: string;
    INBOX_DOMAIN: string;
    SESSION_SECRET: string;
    IP_HASH_SALT: string;
  }
}
