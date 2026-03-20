# PROMPTS.md — AI-First Engineering Process Log

This document records the AI-assisted engineering process used to build the Awsccaasbank CCaaS Terraform Blueprint, demonstrating an **AI-first infrastructure engineering** methodology.

## Git Identity (Placeholder)

> **IMPORTANT**: This repository was initialized with a placeholder git identity:
> - **Name**: `Vikrant Rathore`
> - **Email**: `vikrant.rathore@awsccaasbank.com.au`
>
> Update these before pushing to a shared remote:
> ```bash
> git config user.name "Your Real Name"
> git config user.email "your.real@email.com"
> ```

## Methodology

This project was scaffolded using Claude Code (Anthropic's AI coding assistant) acting as a Senior Platform Engineer. The approach:

1. **Prompt-driven architecture** — High-level requirements were expressed as natural language prompts, with the AI translating them into modular Terraform infrastructure code.
2. **Parallel module generation** — Independent modules (security, networking, storage, lambda, lex, connect, routing, monitoring) were designed and implemented concurrently.
3. **Compliance by design** — APRA CPS 234 controls were embedded in the initial prompt, not bolted on after the fact.
4. **Iterative refinement** — Initial scaffold was expanded with Kinesis streaming, security guardrails, additional environments, and CI/CD in a second pass.

## Prompt Log

### Prompt 1: Initial Blueprint Scaffold

**Intent**: Create the foundational modular Terraform project structure.

**Key directives**:
- Act as Senior Platform Engineer for Awsccaasbank
- Scaffold modular Terraform CCaaS blueprint
- AWS Amazon Connect as CCaaS platform
- ap-southeast-2 for APRA CPS 234 data sovereignty
- Multi-environment (dev, staging, prod)
- Customer-managed KMS keys for all encryption
- Least-privilege IAM

**Result**: 8 Terraform modules, 3 environments, S3 backend configs, root module composition with dependency graph, contact flow JSON definitions, pre-commit config, GitHub Actions CI/CD (plan/apply/destroy), CODEOWNERS.

### Prompt 2: Expanded Requirements

**Intent**: Add enterprise-grade capabilities to the initial scaffold.

**Key directives**:
- Add `test` and `qa` environments (5 total)
- SAML federation for Connect identity management
- Kinesis Data Streams for real-time CTR and agent event analytics
- `security_guardrails` module with AWS Config rules for APRA CPG 234 conformance
- VPC PrivateLink for Connect Voice ID
- Unified `deploy.yml` CI/CD with OIDC federation, Checkov security scanning, manual prod approval
- Python Boto3 validation script for operational readiness
- Mermaid HLD in README
- PROMPTS.md for AI-first process documentation

**Result**: Kinesis streaming (CTR + agent events + Firehose), security guardrails module (16 Config rules + CloudTrail + S3 account blocks), Voice ID and Kinesis VPC endpoints, deploy.yml with sequential promotion pipeline, validate_readiness.py with IVR simulation, expanded README with Mermaid architecture and CI/CD diagrams.

## Architecture Decisions Made by AI (Validated by Engineer)

| Decision | Rationale |
|----------|-----------|
| Directory-based env isolation (not workspaces) | Safer for banking — prevents accidental cross-env state operations |
| Separate KMS keys per purpose (4 keys) | Independent rotation, audit, and access policies per data class |
| Per-function Lambda IAM roles (not shared) | True least-privilege; each function only accesses what it needs |
| Kinesis ON_DEMAND mode for non-prod | Cost optimization; prod can switch to PROVISIONED for capacity planning |
| Contact flows as version-controlled JSON | Enables code review, diff tracking, and rollback for IVR logic |
| Sequential CI/CD promotion (dev→test→qa→staging→prod) | Progressive confidence building; issues caught before reaching production |
| VPC PrivateLink for Voice ID + Kinesis | Keeps sensitive voice biometric and event data off public internet |

## Observations

- **Module dependency graph** was correctly inferred: security → networking → storage → lambda → lex → connect → routing → monitoring
- **APRA CPS 234 mapping** was accurate for: data sovereignty, encryption at rest/transit, access control, audit logging, network isolation
- **Contact flow JSON** structure follows Amazon Connect `Version: 2019-10-30` format correctly
- **Lex V2 intents** were domain-appropriate for Australian retail banking (balance, lost card, branch hours)

## Tooling

- **AI**: Claude Code (claude.ai/code) — Claude Opus 4.6
- **IaC**: Terraform >= 1.7.0, AWS Provider >= 5.40.0
- **Security**: Checkov, tfsec, TFLint
- **CI/CD**: GitHub Actions with OIDC federation
- **Validation**: Python 3.12 + Boto3
