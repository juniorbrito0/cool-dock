# Design

Load for anything visual — app UI, marketing sites, icons, graphics.

## Use Claude Design
- For any design or UI work, invoke the **frontend-design** skill (`/frontend-design`) to generate distinctive, production-grade interfaces — and use **Canva** (MCP) for visual assets, graphics, and anything that needs a real design tool. Don't suggest Figma unless the project already uses it.
- Avoid generic AI aesthetics. Aim for a distinctive, branded look with intentional palette, type, motion, and spacing.

## A design system per project
- **Every project that has a UI gets its own design system** — not a one-off style. Create and maintain it as the single source of truth for that project:
  - Web: design tokens (CSS custom properties / Tailwind theme) + a short `docs/design-system.md` (or a `design-system/` folder) documenting palette, type scale, spacing, motion, components.
  - Apple apps: an asset catalog with dynamic (light/dark) colors + a Swift tokens file; document the identity in the project.
- Build the design system **first**, then build screens/pages that consume its tokens — never hardcode values that belong in the system.
- Each project's system is distinctive to that product (its own palette, accent, signature motion), not a copy of another project's.
- Dark mode is mandatory for apps and expected for sites; tokens must be adaptive, never hardcoded light values.
