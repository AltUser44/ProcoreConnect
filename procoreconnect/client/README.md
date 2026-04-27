# ProcoreConnect (client)

**React + TypeScript + Vite** SPA. The **nginx** runtime image proxies `/api/*` to the Rails service; see the root **[`README.md`](../../README.md)** for architecture and Docker.

**Local dev (API on another port):** from this directory, `npm install` / `npm run dev` (Vite default **3001** with API proxy in `vite.config.ts` if configured).

**Production build:** `npm run build` — used by the multi-stage `Dockerfile` in this folder.

For ESLint / Vite details, see `package.json` and `vite.config.ts`.
