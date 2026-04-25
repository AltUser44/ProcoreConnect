# Be sure to restart your server when you modify this file.

# CORS configuration for the React TypeScript client.
# Default origin is the React dev server on http://localhost:3001 (Rails runs on :3000).
# Override in production via the CORS_ORIGINS env var (comma-separated list).

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGINS", "http://localhost:3001").split(",").map(&:strip)

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: %w[Authorization]
  end
end
