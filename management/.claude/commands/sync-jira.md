Sync latest Jira data into local management files.

1. Pull Q1 planned items: `acli jira workitem search --jql "project = PDCR AND key in (PDCR-451, PDCR-432, PDCR-422, PDCR-404, PDCR-417, PDCR-167, PDCR-411, PDCR-409, PDCR-405, PDCR-446, PDCR-418, PDCR-434, PDCR-433, PDCR-443, PDCR-444, PDCR-406, PDCR-412)" --fields "key,summary,status,assignee,issuetype"`
2. Compare status to what's in project summary files
3. Flag any discrepancies (e.g., item moved to Done in Jira but still listed as active locally)
4. Propose updates to local files if needed
5. Update timeline.md with any new milestone dates if available
