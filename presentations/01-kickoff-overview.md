---
marp: true
theme: default
class: lead
paginate: true
backgroundColor: "#0078D4"
color: "#ffffff"
style: |
  section {
    font-family: "Segoe UI", sans-serif;
    background-color: #0078D4;
    color: #ffffff;
  }
  section.slide {
    background-color: #ffffff;
    color: #1a1a1a;
  }
  section.slide h2 {
    color: #0078D4;
    border-bottom: 3px solid #0078D4;
    padding-bottom: 0.2em;
  }
  section.slide table {
    width: 100%;
    font-size: 0.85em;
  }
  section.slide th {
    background-color: #0078D4;
    color: #ffffff;
  }
  code {
    background-color: #f0f4ff;
    color: #1a1a1a;
  }
  section.dark {
    background-color: #1a1a2e;
    color: #ffffff;
  }
  section.dark h2 {
    color: #50b8f8;
  }
---

# Fabric + Git Essentials
## Version Control Workshop

**Brandon Campbell**
April 2026

---
<!-- class: slide -->

## Agenda

| Time | Session |
|------|---------|
| 09:00–09:20 | **Kickoff** — Objectives, roles, prerequisites |
| 09:20–10:15 | Version control in Fabric & PBIP |
| 10:30–11:30 | 🧪 **Lab 1** — Connect workspace to Git |
| 11:30–12:15 | Collaboration patterns & governance |
| 13:00–13:45 | Deployment strategy: Dev → Test → Prod |
| 13:45–14:45 | 🧪 **Lab 2** — CI pipeline for PBIP |
| 15:00–16:00 | 🧪 **Lab 3** — Fabric Deployment Pipelines |
| 16:00–16:30 | Publishing artifacts & release checklist |
| 16:30–17:00 | Power BI Embedded POC + comms plan |

---
<!-- class: slide -->

## Workshop Objectives

By the end of today you will be able to:

- ✅ Connect a Fabric workspace to Azure DevOps or GitHub
- ✅ Work in **isolated feature branches** without breaking shared workspaces
- ✅ Build a **CI pipeline** that validates PBIP artifacts automatically
- ✅ Use **Fabric Deployment Pipelines** to promote content Dev → Test → Prod
- ✅ Apply governance and release checklists before every production push

---
<!-- class: slide -->

## Who Is This Workshop For?

| Role | What You'll Take Away |
|------|-----------------------|
| **BI Developer** | Branch-based workflow, PR process, isolated feature workspaces |
| **Data Engineer** | PBIP artifact structure, CI validation, DAX unit testing |
| **DevOps / Platform** | YAML pipeline patterns, Fabric REST API, Key Vault integration |
| **BI Lead / Manager** | Governance model, RACI, approval gates, release checklists |

---
<!-- class: slide -->

## Prerequisites Checklist

Before we start, confirm you have:

- [ ] Access to a **Fabric capacity-backed workspace** (F2+, Contributor or higher)
- [ ] Latest **Power BI Desktop** installed
- [ ] **VS Code** with Git extensions installed
- [ ] Access to **Azure DevOps or GitHub** — can create branches & PRs
- [ ] Fabric **Git integration admin toggle** enabled in your tenant
- [ ] **PAT or service principal** credentials ready
- [ ] Sample PBIP starter project cloned locally *(provided by facilitator)*

---
<!-- class: dark -->

## What Is PBIP?

**Power BI Projects (.pbip)** store reports and semantic models as **human-readable text files**:

```
/fabric-workspace
  /SalesReport.Report
    report.json           ← visuals, pages, formatting
    definition.pbir
  /SalesModel.SemanticModel
    model.bim             ← or TMDL folder
    definition/
      tables/
        Sales.tmdl        ← measures, columns, relationships
      relationships.tmdl
```

This makes every change **diff-able, reviewable, and automatable**.

---
<!-- class: slide -->

## Why Git + Fabric?

Without Git:
- Changes made directly in shared workspaces
- No review process — errors reach production
- No history — can't roll back a bad deployment
- One developer blocks others

With Git:
- Every change is a **commit** with an author and message
- PRs enforce **peer review** before anything hits shared workspaces
- CI pipelines **catch errors automatically**
- Parallel development with **zero conflicts**

---
<!-- class: slide -->

## The Big Picture

```
Developer → Feature Branch → PR → CI Pipeline → main
                                                   ↓
                                            Dev Workspace (Git sync)
                                                   ↓
                                         Deployment Pipeline
                                          Dev → Test → Prod
```

Every promotion is **validated, reviewed, and logged**.

---
<!-- class: lead -->

# Let's get started

**Next: Version Control in Fabric & PBIP**
`09:20 → 10:15`
