# Power BI DAX Measures for Credentialing Data Validation Dashboard

This document contains all DAX measures for the Credentialing Data Validation & BI Reporting System dashboard.

## Validation Summary Measures

### Total Validation Failures
```dax
Total Validation Failures = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Resolved] = FALSE()
)
```

### Total Validation Warnings
```dax
Total Validation Warnings = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Warning",
    ValidationResults[Resolved] = FALSE()
)
```

### Total Validation Passes
```dax
Total Validation Passes = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Pass"
)
```

### Total Unresolved Issues
```dax
Total Unresolved Issues = 
[Total Validation Failures] + [Total Validation Warnings]
```

### Validation Pass Rate
```dax
Validation Pass Rate = 
DIVIDE(
    [Total Validation Passes],
    [Total Validation Passes] + [Total Validation Failures] + [Total Validation Warnings],
    0
) * 100
```

### Validation Failure Rate
```dax
Validation Failure Rate = 
DIVIDE(
    [Total Validation Failures],
    [Total Validation Passes] + [Total Validation Failures] + [Total Validation Warnings],
    0
) * 100
```

## Severity-Based Measures

### Critical Failures
```dax
Critical Failures = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Severity] = "Critical",
    ValidationResults[Resolved] = FALSE()
)
```

### High Severity Failures
```dax
High Severity Failures = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Severity] = "High",
    ValidationResults[Resolved] = FALSE()
)
```

### Medium Severity Issues
```dax
Medium Severity Issues = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] IN {"Fail", "Warning"},
    ValidationResults[Severity] = "Medium",
    ValidationResults[Resolved] = FALSE()
)
```

### Low Severity Warnings
```dax
Low Severity Warnings = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Warning",
    ValidationResults[Severity] = "Low",
    ValidationResults[Resolved] = FALSE()
)
```

## Provider Metrics

### Total Active Providers
```dax
Total Active Providers = 
CALCULATE(
    DISTINCTCOUNT(Providers[ProviderID]),
    Providers[Status] = "Active",
    Providers[IsActive] = TRUE()
)
```

### Providers with Validation Failures
```dax
Providers with Validation Failures = 
CALCULATE(
    DISTINCTCOUNT(ValidationResults[EntityID]),
    ValidationResults[EntityType] = "Provider",
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Resolved] = FALSE()
)
```

### Provider Data Quality Score
```dax
Provider Data Quality Score = 
VAR TotalProviderValidations = 
    CALCULATE(
        COUNTROWS(ValidationResults),
        ValidationResults[EntityType] = "Provider"
    )
VAR ProviderFailures = 
    CALCULATE(
        COUNTROWS(ValidationResults),
        ValidationResults[EntityType] = "Provider",
        ValidationResults[ValidationStatus] = "Fail",
        ValidationResults[Resolved] = FALSE()
    )
RETURN
    IF(
        TotalProviderValidations > 0,
        100 - (DIVIDE(ProviderFailures, TotalProviderValidations, 0) * 100),
        100
    )
```

### Providers Requiring Attention
```dax
Providers Requiring Attention = 
CALCULATE(
    DISTINCTCOUNT(Providers[ProviderID]),
    Providers[Status] = "Active",
    Providers[IsActive] = TRUE(),
    RELATED(ValidationResults[ValidationStatus]) IN {"Fail", "Warning"},
    RELATED(ValidationResults[Resolved]) = FALSE()
)
```

## Credential Metrics

### Total Active Credentials
```dax
Total Active Credentials = 
CALCULATE(
    COUNTROWS(Credentials),
    Credentials[Status] = "Active"
)
```

### Expiring Credentials (30 Days)
```dax
Credentials Expiring 30 Days = 
CALCULATE(
    COUNTROWS(Credentials),
    Credentials[Status] = "Active",
    Credentials[ExpirationDate] >= TODAY(),
    Credentials[ExpirationDate] <= TODAY() + 30
)
```

### Expiring Credentials (60 Days)
```dax
Credentials Expiring 60 Days = 
CALCULATE(
    COUNTROWS(Credentials),
    Credentials[Status] = "Active",
    Credentials[ExpirationDate] >= TODAY(),
    Credentials[ExpirationDate] <= TODAY() + 60
)
```

### Expired Credentials
```dax
Expired Credentials = 
CALCULATE(
    COUNTROWS(Credentials),
    Credentials[ExpirationDate] < TODAY(),
    Credentials[Status] <> "Expired"
)
```

### Credential Validation Failures
```dax
Credential Validation Failures = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[EntityType] = "Credential",
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Resolved] = FALSE()
)
```

### Credential Compliance Rate
```dax
Credential Compliance Rate = 
VAR TotalActiveCreds = [Total Active Credentials]
VAR ExpiredOrExpiring = [Expired Credentials] + [Credentials Expiring 30 Days]
RETURN
    IF(
        TotalActiveCreds > 0,
        100 - (DIVIDE(ExpiredOrExpiring, TotalActiveCreds, 0) * 100),
        100
    )
```

## Entity Metrics

### Total Active Entities
```dax
Total Active Entities = 
CALCULATE(
    DISTINCTCOUNT(Entities[EntityID]),
    Entities[Status] = "Active",
    Entities[IsActive] = TRUE()
)
```

### Entity Validation Failures
```dax
Entity Validation Failures = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[EntityType] = "Entity",
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Resolved] = FALSE()
)
```

### Entities with Incomplete Data
```dax
Entities with Incomplete Data = 
CALCULATE(
    DISTINCTCOUNT(Entities[EntityID]),
    Entities[Status] = "Active",
    OR(
        ISBLANK(Entities[AddressLine1]),
        ISBLANK(Entities[City]),
        ISBLANK(Entities[State]),
        ISBLANK(Entities[ZipCode])
    )
)
```

## Trend Analysis Measures

### Validation Failures Trend (7 Days)
```dax
Failures Trend 7 Days = 
CALCULATE(
    [Total Validation Failures],
    FILTER(
        ALL(ValidationResults[ValidationDate]),
        ValidationResults[ValidationDate] >= TODAY() - 7
    )
)
```

### Validation Failures Trend (30 Days)
```dax
Failures Trend 30 Days = 
CALCULATE(
    [Total Validation Failures],
    FILTER(
        ALL(ValidationResults[ValidationDate]),
        ValidationResults[ValidationDate] >= TODAY() - 30
    )
)
```

### Failures Change (Day over Day)
```dax
Failures Change DoD = 
VAR TodayFailures = 
    CALCULATE(
        [Total Validation Failures],
        ValidationResults[ValidationDate] = TODAY()
    )
VAR YesterdayFailures = 
    CALCULATE(
        [Total Validation Failures],
        ValidationResults[ValidationDate] = TODAY() - 1
    )
RETURN
    TodayFailures - YesterdayFailures
```

### Failures Change (Week over Week)
```dax
Failures Change WoW = 
VAR ThisWeekFailures = 
    CALCULATE(
        [Total Validation Failures],
        ValidationResults[ValidationDate] >= TODAY() - 7,
        ValidationResults[ValidationDate] <= TODAY()
    )
VAR LastWeekFailures = 
    CALCULATE(
        [Total Validation Failures],
        ValidationResults[ValidationDate] >= TODAY() - 14,
        ValidationResults[ValidationDate] < TODAY() - 7
    )
RETURN
    ThisWeekFailures - LastWeekFailures
```

## Rule Performance Measures

### Most Common Validation Failures
```dax
Top Validation Failures = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Resolved] = FALSE()
)
```

### Rule Failure Count
```dax
Rule Failure Count = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[ValidationStatus] = "Fail",
    ValidationResults[Resolved] = FALSE()
)
```

### Average Failures per Rule
```dax
Average Failures per Rule = 
DIVIDE(
    [Total Validation Failures],
    DISTINCTCOUNT(ValidationResults[RuleCode]),
    0
)
```

## Resolution Metrics

### Resolved Issues (Last 30 Days)
```dax
Resolved Issues 30 Days = 
CALCULATE(
    COUNTROWS(ValidationResults),
    ValidationResults[Resolved] = TRUE(),
    ValidationResults[ResolvedDate] >= TODAY() - 30
)
```

### Resolution Rate
```dax
Resolution Rate = 
VAR TotalIssues = [Total Validation Failures] + [Total Validation Warnings]
VAR Resolved = 
    CALCULATE(
        COUNTROWS(ValidationResults),
        ValidationResults[Resolved] = TRUE()
    )
RETURN
    IF(
        TotalIssues > 0,
        DIVIDE(Resolved, TotalIssues + Resolved, 0) * 100,
        0
    )
```

### Average Resolution Time (Days)
```dax
Average Resolution Time = 
AVERAGEX(
    FILTER(
        ValidationResults,
        ValidationResults[Resolved] = TRUE() &&
        NOT(ISBLANK(ValidationResults[ResolvedDate])) &&
        NOT(ISBLANK(ValidationResults[ValidationDate]))
    ),
    DATEDIFF(
        ValidationResults[ValidationDate],
        ValidationResults[ResolvedDate],
        DAY
    )
)
```

## Validation Run Metrics

### Last Validation Run Time
```dax
Last Validation Run Time = 
CALCULATE(
    MAX(ValidationRunLog[RunStartTime]),
    ValidationRunLog[RunStatus] = "Completed"
)
```

### Last Validation Run Duration
```dax
Last Validation Run Duration = 
CALCULATE(
    MAX(ValidationRunLog[ExecutionTimeSeconds]),
    ValidationRunLog[RunStatus] = "Completed"
)
```

### Validation Runs Today
```dax
Validation Runs Today = 
CALCULATE(
    COUNTROWS(ValidationRunLog),
    ValidationRunLog[RunStartTime] >= TODAY(),
    ValidationRunLog[RunStartTime] < TODAY() + 1
)
```

### Successful Validation Runs (Last 30 Days)
```dax
Successful Runs 30 Days = 
CALCULATE(
    COUNTROWS(ValidationRunLog),
    ValidationRunLog[RunStatus] = "Completed",
    ValidationRunLog[RunStartTime] >= TODAY() - 30
)
```

## KPI Measures

### Overall Data Quality Score
```dax
Overall Data Quality Score = 
VAR ProviderScore = [Provider Data Quality Score] * 0.4
VAR CredentialScore = [Credential Compliance Rate] * 0.4
VAR ValidationScore = [Validation Pass Rate] * 0.2
RETURN
    ProviderScore + CredentialScore + ValidationScore
```

### Data Health Status
```dax
Data Health Status = 
SWITCH(
    TRUE(),
    [Overall Data Quality Score] >= 95, "Excellent",
    [Overall Data Quality Score] >= 85, "Good",
    [Overall Data Quality Score] >= 70, "Fair",
    [Overall Data Quality Score] >= 50, "Poor",
    "Critical"
)
```

### Issues Requiring Immediate Attention
```dax
Issues Requiring Immediate Attention = 
[Critical Failures] + [High Severity Failures] + [Expired Credentials]
```

## Time Intelligence Measures

### Validation Failures (This Month)
```dax
Failures This Month = 
CALCULATE(
    [Total Validation Failures],
    FILTER(
        ALL(ValidationResults[ValidationDate]),
        MONTH(ValidationResults[ValidationDate]) = MONTH(TODAY()) &&
        YEAR(ValidationResults[ValidationDate]) = YEAR(TODAY())
    )
)
```

### Validation Failures (Last Month)
```dax
Failures Last Month = 
CALCULATE(
    [Total Validation Failures],
    FILTER(
        ALL(ValidationResults[ValidationDate]),
        MONTH(ValidationResults[ValidationDate]) = MONTH(TODAY()) - 1 &&
        YEAR(ValidationResults[ValidationDate]) = YEAR(TODAY())
    )
)
```

### Month over Month Change
```dax
Failures MoM Change = 
[Failures This Month] - [Failures Last Month]
```


