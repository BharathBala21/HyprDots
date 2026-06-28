# HyprDots documentation AI

A Cloudflare Worker that answers questions using only the committed HyprDots MDX documentation. Relevant sections are selected locally and sent to Groq with strict grounding instructions. The Groq API key is never exposed to the browser.

## Deploy

```bash
cd docs-ai
npm install
npx wrangler login
npx wrangler secret put GROQ_API_KEY
npm run deploy
```

Paste the Groq API key only when Wrangler prompts for it. Do not add it to a file or commit it.

The deploy command prints a URL similar to:

```text
https://hyprdots-docs-ai.<cloudflare-subdomain>.workers.dev
```

Add that URL to the `header.links` array in the repository's root `docs.json`:

```json
{
  "title": "Ask AI",
  "href": "https://hyprdots-docs-ai.<cloudflare-subdomain>.workers.dev",
  "cta": true
}
```

## Local development

Create `docs-ai/.dev.vars` with `GROQ_API_KEY=...`, then run `npm run dev`. The file is ignored by Git.

Run `npm run build:context` whenever docs change. Both `npm run dev` and `npm run deploy` do this automatically.
