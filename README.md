# the-system

A Tauri + Vue desktop app for a growing suite of personal-notes flows, backed by a plain folder of JSON files on disk.

## Prerequisites

- Node.js and npm
- Rust toolchain (`cargo`)
- [Tauri prerequisites](https://v2.tauri.app/start/prerequisites/) for your OS (e.g. `webkit2gtk` on Linux)

## Setup

```bash
npm install
```

## Development

```bash
npm run dev          # frontend only, in a browser (no filesystem access)
npm run tauri dev    # full desktop app, with hot reload
```

On first launch, the app asks you to pick a data folder — a directory of note JSON files it reads from and writes to.

## Build

```bash
npm run build              # type-check + build the frontend bundle
npm run tauri:build        # build the desktop app for your platform
npm run tauri:build:deb    # build a .deb package (Linux)
```

## Type-checking

```bash
npx vue-tsc -b        # frontend
cd src-tauri && cargo check   # backend
```

## Data format

Notes are flat `*.json` files directly inside the data folder. Each file has at least a `primaryType` field; flow-specific fields (e.g. `title`, `body`, `triaged`) vary by note type. See `example_file_1.json` / `example_file_2.json` for samples.

## Flows

- **Scratchpad Triage** — surfaces notes with `primaryType: "scratchpad"` and no `triaged: "true"` one at a time, in random order, with Keep / Delete / Defer actions. Delete offers an Undo toast.
