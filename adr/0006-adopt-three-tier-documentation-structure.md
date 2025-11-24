# 6. Adopt Three-Tier Documentation Structure

Date: 2025-11-10

## Status

Proposed

## Context

Our documentation is currently split across Google Drive and the GitHub Wiki.  
Google Drive contains both temporary collaboration documents (meeting notes, planning) and long-term references (processes, engineering documentation, onboarding materials).  
The GitHub Wiki serves contributor-specific information but lacks space for evolving internal documentation and team knowledge.

This fragmentation makes it hard to find accurate, up-to-date information.

The primary forces influencing this decision are:
- The need for **long-term maintainability** and a clear source of truth.  
- The need to **retain Google Drive** for early-stage collaboration.  
- The need to **support external contributors** through the GitHub Wiki.  
- The requirement to **collaborate effectively with other teams** while maintaining structure internally.

## Decision

We will **adopt a three-tier documentation structure** using Confluence, Google Drive, and the GitHub Wiki, each serving a distinct role:

- **Confluence** will serve as the canonical home for finalized and evergreen documentation.  
  It will include:
  - Engineering overviews and architecture  
  - Team norms, onboarding materials, and operational processes  
  - Strategic and finalized proposals  
  - References to key external documents  

- **Google Drive** will continue to serve as the workspace for in-progress, exploratory, and collaborative work.  
  It will include:
  - Meeting notes and collaborative planning documents  
  - Early-stage proposals or design explorations  
  - Research spikes and technical investigations  
  - Presentations and learning summaries shared within the team  
  - Cross-team collaboration documents  

  When an investigation or proposal results in a technical decision, the responsible engineer will author an **ADR in GitHub** to record that decision. After a decision is made, any resulting documentation that becomes part of long-term knowledge (e.g., implementation guides, architecture updates) will be written in **Confluence**, with optional links back to the relevant Drive documents for historical context. 
  Google Drive will therefore remain the home for **exploration and discovery**, while **GitHub ADRs** and **Confluence** represent **decision** and **documentation**, respectively.

- **GitHub Wiki** will focus on **contributor enablement** — documentation that helps new or external contributors build, test, and submit changes to this repository.  
  It will include:
  - Build and setup instructions  
  - Development workflows (branching, PRs, CI expectations)  
  - Coding standards and review guidelines  
  - How to test, run, and validate changes locally  

  The Wiki must remain self-contained so contributors can successfully engage without internal access.  
  Internal Confluence pages may be referenced in name only (e.g., “For Mozilla staff, see the internal Confluence page on Swift Concurrency for more details”) but should never be linked directly to ensure a good user experience for our contributors who can't access those documents.

We will retire outdated or redundant Drive folders (e.g., Vision-Strategy, Test-Artifacts, Ops-Docs) and archive them appropriately.  
Drive will only retain folders necessary for collaboration, planning, and interviewing.

## Consequences

**Positive outcomes:**
- Documentation will be easier to locate and maintain.  
- Clear boundaries between collaborative, internal, and contributor-facing documentation.  
- Reduced redundancy and confusion over document ownership.  
- Improved onboarding and cross-team transparency.  

**Negative or neutral outcomes:**
- Migration will require coordinated effort and time.  
- Team members will need to learn new Confluence conventions and responsibilities.  
- Some temporary duplication between Drive and Confluence may occur during transition.  

This structure improves clarity, sustainability, and collaboration across our team and partner organizations.  
Confluence becomes the single source of truth for finalized documentation, while Drive and the GitHub Wiki retain their respective roles for collaboration and contribution.
