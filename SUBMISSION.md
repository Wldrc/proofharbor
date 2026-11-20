# ProofHarbor — hackathon submission (FINAL, revised with Gemma + ChatGPT + Gemini critiques)

## Project name
ProofHarbor

## Tagline
On-chain work records for Agent ID holders — gas-optimized for AI agents. One proof is enough; daily liveness check-ins are an optional extra.

## Description (submission form)
An Agent ID establishes an agent's on-chain identity, but identity alone doesn't communicate activity. **ProofHarbor turns Agent ID ownership into a verifiable, persistent activity history for AI agents**: a public logbook on BNB Chain where a holder anchors proof of real work to their Agent ID. One submitted proof is already a complete record — the daily liveness check-in is an optional extra for agents that also want to show continuous activity.

**What holders can do**

1. **Log work references — the core action, and one is enough.** Attach the hash of any completed on-chain action (a mint, a swap, a settlement, a delivered bounty, a deployed contract) with a short context note. ProofHarbor stores the reference permanently under the holder's Agent ID. The hash is inspectable evidence that the transaction exists; ProofHarbor does not re-execute external transactions and does not claim to have independently verified the underlying task — it creates an immutable, timestamped index linking real on-chain activity to the agent's identity.
2. **Prove liveness once a day (optional extra).** Each daily check-in creates a verifiable on-chain record of participation in a single transaction: it updates the day streak and appends a permanent activity record at the same time. A day is a UTC calendar day; miss a day and the streak restarts at 1.
3. **Sign the public guestbook** and appear on the public leaderboard, ranked by current streak, then by number of work references. Anyone can open any holder's full history — no account, no login.

**Deep Agent ID integration.** Every write function checks `balanceOf` on the official Agent ID registry (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F) inside the contract itself — identity is enforced on-chain, not in the frontend. Every check-in and work reference is recorded against the Agent ID holder's wallet at submission time, creating a public, persistent history linked to that identity. And it has to be Agent ID specifically: an Agent ID is non-transferable and permanent — one identity per agent, for life — so a track record built under it cannot be bought, sold, or moved to a fresh wallet. Any NFT could gate a logbook; only a non-transferable identity makes the logbook mean something.

**Built for autonomous execution.** Every action is a single, self-contained transaction — no token approvals, no multi-step handshakes, no off-chain signatures to coordinate. Measured costs on BNB Chain stay negligible for automated loops: the core action — logging one work reference — costs ≈ 0.0000089 BNB once (178,932 gas), a guestbook signature ≈ 0.0000038 BNB (75,867 gas), and the optional daily liveness proof costs ≈ 0.000014 BNB the first time (282,744 gas — one call writes both the streak state and the permanent activity record) and ≈ 0.0000067 BNB on repeat days (133,057 gas) — all at a gas price of 0.05 gwei, the level ordinary wallets pay on BNB Chain today. Even an agent that checks in every day for a full year would spend only ≈ 0.0024 BNB in fees. The full ABI is published in the open-source repository, so autonomous agents can call the contract directly; human operators use the web interface.

**Safety by design.** The contract holds no funds, requests no token approvals, has no owner, no admin keys, and no upgradeability. Records are publicly verifiable on-chain and cannot be silently modified or deleted through an administrative interface. Source code is open and verified on BscScan; users sign every transaction themselves in their own wallet.

**Why it matters.** An Agent ID proves an agent exists, but not whether it is active or reliable. ProofHarbor turns static identity tokens into a public, append-only operational history — indexed work hashes and optional uptime streaks — that other protocols, builders, or operators can inspect on-chain before interacting with an agent. It provides that record without promising rewards or financial returns.

## Contract
- Network: BNB Chain (BSC mainnet)
- Address: _(filled in after deployment)_
- Source: https://github.com/Wldrc/proofharbor

## Community X post (final draft — Sapo posts it himself from @TTran588, after deployment)
⚓ ProofHarbor: an on-chain work log for Agent ID holders on BNB Chain. One proof is enough — ≈ 0.0000089 BNB, once. Optional daily liveness check-ins for agents that want more. No funds held, no approvals. #BinanceWalletHackathon #AgenticWallet

## Free-AI critique log (2026-11-20)
- Gemma 4 (Gemini API): ~77/100 (depth 22/30, practicality 23/25, completeness 20/25, creativity 12/20). Fixes: "check-in" → "liveness proof"; work-proof examples; "why Agent ID specifically" paragraph.
- ChatGPT free: 78/100 (26/30, 20/25, 17/25, 15/20). Fixes applied: honest work-reference framing (hash = inspectable evidence, NOT independent verification), reproducible gas-cost wording, day/streak/leaderboard rules spelled out, records keyed to holder wallet at submission time.
- Gemini web: 7.43/10 (depth 7.5, practicality 8.5, completeness 7.0, creativity 6.5). Fixes applied: explained what the 282,744 gas buys (streak + permanent log in one call), added agent-ready ABI line, scannable structure. Open design note (NOT changed): Gemini suggested keying records per tokenId instead of per wallet — kept per-wallet by design decision; flagged to Sapo 2026-11-20.
