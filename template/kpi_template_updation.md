### STEP – MODULE CHANGE ANALYSIS

**Project Name:** [Project Name]  
**Version:** [Version]   
**Date:** [Date]   
**Author:** [Author]   

Before generating KPIs, identify and categorize modules from the PRD.

#### Existing Modules / Features (Reference Only)

| Module      | Current Functionality |
| ----------- | --------------------- |
| Module Name | Existing behavior     |

Do NOT generate new KPIs unless the module is being modified.

---

#### New Modules / Features

| Module      | Description       |
| ----------- | ----------------- |
| Module Name | New functionality |

Generate complete KPI coverage.

---

#### Modified Modules / Features

| Module      | Existing Behavior     | Updated Behavior |
| ----------- | --------------------- | ---------------- |
| Module Name | Current functionality | Requested change |

Generate KPIs only for the modified functionality and its impact.

---

### STEP – KPI GENERATION

Generate KPIs only for:

* New Modules
* Modified Modules
* Impacted Integrations
* Impacted Security Controls
* Impacted Audit/Compliance Requirements
* Impacted Reporting Features

Do NOT regenerate KPIs for unchanged modules.

Format:

| KPI Number | Module | KPI Name | Description | Criteria |
| ---------- | ------ | -------- | ----------- | -------- |

Requirements:

* KPIs must be measurable, testable, and verifiable.
* KPIs must map to user actions or system outcomes.
* KPIs must support QA, UAT, and business validation.
* Include functional, security, audit, compliance, operational, reporting, and integration KPIs where applicable.
* Cover edge cases introduced by the new or modified functionality.
* Generate regression KPIs only when existing functionality is impacted.

---

### STEP – IMPACT ANALYSIS

Identify affected areas.

| Area      | Impact Type    | Description |
| --------- | -------------- | ----------- |
| UI        | New / Modified | Description |
| API       | New / Modified | Description |
| Database  | New / Modified | Description |
| Security  | New / Modified | Description |
| Reporting | New / Modified | Description |

---

### STEP – IMPLEMENTATION ROADMAP

# Development Timeline

| Sprint | Focus Area | Deliverables |
| ------ | ---------- | ------------ |

---

# Success Criteria

| Category | Success Metric | Target |
| -------- | -------------- | ------ |

---

### OUTPUT REQUIREMENTS

* Focus only on new and modified functionality.
* Treat existing modules as reference unless impacted.
* Generate regression coverage for affected existing modules.
* Use markdown tables throughout.
* Ensure output can directly support BRD, PRD, QA Strategy, UAT, and Development Planning.
