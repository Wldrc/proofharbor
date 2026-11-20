# ProofHarbor — hackathon submission (FINAL, revised with Gemma + ChatGPT + Gemini critiques)

## Project name
ProofHarbor

## Tagline
Daily liveness proofs and on-chain work records for Agent ID holders — gas-optimized for AI agents.

## Description (submission form)
An Agent ID establishes an agent's on-chain identity, but identity alone doesn't communicate activity. **ProofHarbor turns Agent ID ownership into a verifiable, persistent activity history for AI agents**: a public logbook on BNB Chain where every Agent ID holder builds an identity-bound timeline of daily activity records and submitted work references.

**What holders can do**

1. **Prove liveness once a day.** Each daily check-in creates a verifiable on-chain record of participation in a single transaction: it updates the day streak and appends a permanent activity record at the same time. A day is a UTC calendar day; miss a day and the streak restarts at 1.
2. **Log work references.** Attach the hash of any completed on-chain action (a mint, a swap, a settlement, a delivered bounty, a deployed contract) with a short context note. ProofHarbor stores the reference permanently under the holder's Agent ID. The hash is inspectable evidence that the transaction exists; ProofHarbor does not re-execute external transactions and does not claim to have independently verified the underlying task — it creates an immutable, timestamped index linking real on-chain activity to the agent's identity.
3. **Sign the public guestbook** and appear on the public leaderboard, ranked by current streak, then by number of work references. Anyone can open any holder's full history — no account, no login.

**Deep Agent ID integration.** Every write function checks `balanceOf` on the official Agent ID registry (0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F) inside the contract itself — identity is enforced on-chain, not in the frontend. Every check-in and work reference is recorded against the Agent ID holder's wallet at submission time, creating a public, persistent history linked to that identity. And it has to be Agent ID specifically: an Agent ID is non-transferable and permanent — one identity per agent, for life — so a track record built under it cannot be bought, sold, or moved to a fresh wallet. Any NFT could gate a logbook; only a non-transferable identity makes the logbook mean something.

**Built for autonomous execution.** Every action is a single, self-contained transaction — no token approvals, no multi-step handshakes, no off-chain signatures to coordinate. Measured costs on BNB Chain stay negligible for automated loops: a daily liveness proof costs ≈ 0.000074 BNB (282,744 gas at 0.26 gwei — one call writes both the streak state and the permanent activity record), a work reference ≈ 0.000047 BNB (178,932 gas), a guestbook signature ≈ 0.000020 BNB (75,867 gas). At the measured gas usage and an assumed gas price of 0.26 gwei, 365 daily check-ins would cost approximately 0.027 BNB in fees. The full ABI is published in the open-source repository, so autonomous agents can call the contract directly; human operators use the web interface.

**Safety by design.** The contract holds no funds, requests no token approvals, has no owner, no admin keys, and no upgradeability. Records are publicly verifiable on-chain and cannot be silently modified or deleted through an administrative interface. Source code is open and verified on BscScan; users sign every transaction themselves in their own wallet.

**Why it matters.** An Agent ID proves an agent exists, but not whether it is active or reliable. ProofHarbor turns static identity tokens into a public, append-only operational history — uptime streaks and indexed work hashes — that other protocols, builders, or operators can inspect on-chain before interacting with an agent. It provides that record without promising rewards or financial returns.

## Contract
- Network: BNB Chain (BSC mainnet)
- Address: _(filled in after deployment)_
- Source: _(GitHub repo link, filled in after publishing)_

## Community X post (final draft — Sapo posts it himself from @TTran588, after deployment)
⚓ ProofHarbor: daily liveness proofs + an on-chain work log for Agent ID holders on BNB Chain. Gas-optimized for AI agents — one liveness proof ≈ 0.000074 BNB. No funds held, no approvals. #BinanceWalletHackathon #AgenticWallet

## Free-AI critique log (2026-11-20)
- Gemma 4 (Gemini API): ~77/100 (depth 22/30, practicality 23/25, completeness 20/25, creativity 12/20). Fixes: "check-in" → "liveness proof"; work-proof examples; "why Agent ID specifically" paragraph.
- ChatGPT free: 78/100 (26/30, 20/25, 17/25, 15/20). Fixes applied: honest work-reference framing (hash = inspectable evidence, NOT independent verification), reproducible gas-cost wording, day/streak/leaderboard rules spelled out, records keyed to holder wallet at submission time.
- Gemini web: 7.43/10 (depth 7.5, practicality 8.5, completeness 7.0, creativity 6.5). Fixes applied: explained what the 282,744 gas buys (streak + permanent log in one call), added agent-ready ABI line, scannable structure. Open design note (NOT changed): Gemini suggested keying records per tokenId instead of per wallet — kept per-wallet by design decision; flagged to Sapo 2026-11-20.
