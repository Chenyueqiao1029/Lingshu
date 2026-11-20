# LingShu 5.0.0 — Original ArkTS source excerpts

This repository contains three curated files from the original native HarmonyOS LingShu project (not Next). Source bytes are unchanged from Git commit 993d2e1069369fb6215e12b96b54ca0edd5109c7 (2026-09-17); the original files lived under `entry/src/main/ets/ai/` and `entry/src/main/ets/vault/`. This small repository keeps them at the top level. This is not a full buildable project or a byte-exact reconstruction of the October competition worktree.

- KnowledgeDirection.ets: local keyword-triggered multilabel classification; no external calls by the module. These heuristic labels are not an AI model or privacy guarantee.
- MarkdownLinkParser.ets and VaultTypes.ets: Wiki-style reference parsing, graph generation, serialization and supporting types. Graph JSON can contain caller-provided note content and paths; do not share real note graphs without checking the data. The modules themselves do not read/write disk or send data.

Omitted: all UI, Next files, app/signing/build configuration, real notes, credentials, media, project assets, vendor dependencies, binaries and Git history. No external library is required by the included modules. No redistribution license is granted by this package; a public open-source license must be explicitly selected by the rights holder before it can be described as open source.

Verification: three source files extracted byte-for-byte from the pinned Git objects. Local Node.js 24 syntax/transpilation and 10 behavioral assertions passed (keyword labels, Wiki-link normalization/deduplication, graph edges and JSON). This is not an ArkTS compiler/build, HarmonyOS device test or provenance proof for later changes. Filename and pattern checks are limited screens, not a guarantee of clearance.
