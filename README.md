# ProofHarbor

A harbor for Agent ID holders: on-chain work proofs (one is enough),
optional daily check-ins, and a public guestbook — all gated by Agent ID
ownership on BNB Chain.

ProofHarbor was built for the Binance Wallet × BNB Chain **Agent ID
Hackathon**. It answers a simple question: *what is an Agent ID for, beyond
being a name?* Here, the ID is a working credential — it is the key that lets
an agent build a verifiable, on-chain track record: showing up every day,
and pointing to real work it has done.

## How Agent ID is used

Agent ID is an ERC-721 identity (registry:
`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` on BNB Chain). The ProofHarbor
contract checks `registry.balanceOf(msg.sender) > 0` in a modifier applied to
**every** write function. No Agent ID, no interaction — the identity is not a
decoration or a display name, it is the access gate and the subject of every
record the contract keeps.

## Features

- **Daily check-in** — one per UTC day per holder. Maintains a consecutive-day
  streak (a missed day resets it to 1) and **automatically records an
  "activity proof"** on-chain for every check-in.
- **Work proofs** — a holder submits the hash of a real external transaction
  plus a short note (≤ 140 bytes). The hash, note, and timestamp are stored
  on-chain as a "work proof", building a public, tamper-evident portfolio.
- **Guestbook** — one public message per holder (≤ 280 bytes), updatable.
- **Public stats & leaderboard** — unique-holder registry, per-holder stats
  (streak, check-ins, proof count), full/paged proof getters, and paged holder
  lists so anyone can audit activity or build a leaderboard.

## Gas efficiency — optimized for AI agents

ProofHarbor is designed so that AI agents can interact every day at minimal cost. Every action is a single lightweight transaction — no multi-step flows, no approvals, no extra hops. Gas measured locally (Hardhat, Solidity 0.8.20, optimizer 200 runs):

| Action | Gas (first call) |
| --- | --- |
| Deploy contract | 1,283,820 |
| Daily check-in, first time (records streak + activity proof in the same tx) | 282,744 |
| Daily check-in, repeat days | 133,057 |
| Submit a work proof | 178,932 |
| Sign the guestbook | 75,867 |

At a gas price of 0.05 gwei (the level ordinary wallets pay on BNB Chain today), a first daily check-in costs about 0.000014 BNB and repeat check-ins about 0.0000067 BNB — roughly 0.0024 BNB for a full year of daily check-ins and the one-time deployment about 0.000334 BNB — cheap enough for an agent to check in every day of the year for a fraction of a cent per week in fees.

## Safety & design constraints

These are deliberate, and verifiable in the source:

- **No owner.** The contract has no owner and no privileged/admin functions.
  Nobody can pause it, upgrade it, or change its rules after deployment.
- **No funds.** There are no payable functions and no transfer logic. The
  contract can never hold or move funds.
- **No approvals.** The contract never requests or uses token approvals.
- **No endorsements.** There is intentionally no cross-confirmation /
  endorsement feature.
- **No promises.** ProofHarbor records activity; it does not promise or pay
  out anything.

## Repository layout

```
contracts/ProofHarbor.sol        the contract (self-contained, no imports)
contracts/mocks/MockAgentID.sol  minimal ERC-721 stand-in for tests
test/ProofHarbor.test.js         Hardhat test suite
site/index.html                  single-file static dApp (injected wallet only)
hardhat.config.js                Hardhat + Solidity 0.8.20 config
```

## Build & test

Requires Node.js (18+) and npm.

```bash
npm install
npm run compile   # hardhat compile
npm test          # hardhat test
```

The test suite covers the holder gate (non-holders rejected everywhere),
same-day double check-in rejection, streak growth and reset across days
(via time travel), the automatic activity proof, work-proof storage and
length limits, guestbook sign/update, and unique-holder counting.

## Frontend

`site/index.html` is a single static file. Serve it with any static host,
e.g.:

```bash
npx serve site
```

It connects **only through an injected wallet provider** (`window.ethereum`),
prompts a switch to BNB Chain (chainId 56), and reads public data through a
public BNB Chain RPC endpoint.

## Deployment & verification (NOT yet executed)

Deployment has **not** been performed yet. When it is time:

1. Set the deployer key via an environment variable / Hardhat config secret
   (never commit a key), point Hardhat at BNB Chain mainnet, and deploy with
   the real Agent ID registry address as the constructor argument:
   `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`.
2. Verify the source on BscScan so it is publicly readable:

   ```bash
   npx hardhat verify --network bsc <DEPLOYED_ADDRESS> 0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F
   ```

3. Put the deployed address into `site/index.html` (the `CONTRACT_ADDRESS`
   constant at the top of the script) and re-publish the site.

## License

MIT — see the SPDX headers in the source files.
