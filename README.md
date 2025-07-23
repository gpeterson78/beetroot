# Work in Progress — Do Not Use Unless You Want to Break Things

# beetroot
**Self-hosted infrastructure stack for families and small groups.**  
Local-first, container-based, CLI-driven — and deeply rooted in transparency.

## Quick Install

[![Install Beetroot](https://img.shields.io/badge/install-beetroot-brightgreen)](https://raw.githubusercontent.com/gpeterson78/beetroot/main/install.sh)

You can install Beetroot with a single command:

```bash
wget -qO- https://raw.githubusercontent.com/gpeterson78/beetroot/main/install.sh | sudo bash
```

Or if you prefer:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/gpeterson78/beetroot/main/install.sh)
```

---

## Why beetroot?

Beets taste like sugary dirt but I love them.  

Like its namesake, **Beetroot** is unpolished, functional, healthy (educational), and grows from the fertile ground sown by all the amazing projects it’s built upon.  It’s for people who like knowing where their data lives.  Who prefer dirt under their nails to scripts they don’t understand.  Who’d rather run one command than push five buttons.

Beetroot tastes like control. I love that too.

---

## Philosophy & Design Goals

### What Is This Project?

**beetroot** is a lightweight platform for managing containerized services like media libraries, blogs, backups, and more. It aims to balance usability with transparency — providing just enough tooling to streamline setup, while keeping the system simple, understandable, and fully under your control.

This project is built with a *CLI-first, API-second, UI-third* mindset: every operation is scriptable and visible, then surfaced through APIs, and finally wrapped in a web interface.

---

### Why Not Use an Existing Tool?

This project isn’t a reaction to any specific tool — it’s the result of *using* them and realizing something was missing:

- Many tools abstract away standard practices behind custom UIs.
- Containerization is simple, why make it more opaque rather that expose it all to debug and learn.
- I like Web UI's, but sometimes I'd just rather a cli.

**beetroot embraces** standard formats like `docker-compose`, `.env` files, and basic scripting. The goal is to work *with* existing tools — not replace them.

The system should show you *how* something is done, not just *that* it was done.

---

### Core Design Goals

- **Transparency Over Abstraction**  
  Users should always be able to see and understand what's happening behind the scenes. If it’s doable from the UI, it should be doable from the CLI — and vice versa.

- **Scriptable and Extendable**  
  All operations are exposed via modular scripts and a local API. You can build on it, automate it, or swap parts as needed.

- **Local-First, Self-Contained**  
  Designed for local or trusted hardware. Remote access is optional and decoupled from critical internal services.

- **Minimal, Modular Architecture**  
  Each component does one job well. The system avoids hidden dependencies or entangled components.

- **Developer and Hacker Friendly**  
  File layout is logical. Everything is in plain sight — services, configs, logs, shared data.

- **Educational by Design**  
  Not just a platform — a teacher. Aimed at people who want to learn and grow their confidence with Linux, Docker, and self-hosting.

---

## Target Audience

- People who want to host their own services with confidence.
- Tinkerers and power users who prefer control over convenience.
- Families or small groups who want data ownership.
- Anyone curious enough to try running their own infrastructure — and willing to look at a CLI once in a while.

---

## Status

beetroot is under active development. The initial goal is to make onboarding and service deployment easy and transparent using:

- A modular CLI toolset (`beetenv`, `beetsync`, `mose`, etc.)
- Docker Compose-based service structure
- A local admin interface running on port **4200**
- An API layer integrated into the web admin, decoupled from Traefik and public access

Eventually, the entire stack will be optionally containerized, web-accessible, and fully pluggable.

---

## More Soon…

This README is a living document — more examples, architecture, usage docs, and diagrams to follow.