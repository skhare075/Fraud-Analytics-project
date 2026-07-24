# Banking Transaction Fraud Analytics

## Project Overview

Analyzed **13.3M banking transactions** representing approximately **$571.8M in transaction value** to identify concentrations of observed fraud exposure across merchant, channel (physical store/online), customer, geography, and time dimensions.

Used **Python** to inspect the source files and validate their schemas before loading the data. Built a **PostgreSQL analytical data model** from raw transaction, customer, card, fraud-label, and Merchant Category Code (MCC) datasets, including cleaned relational tables, **primary key/foreign key (PK/FK) relationships**, and a consolidated analytics view.

Fraud analysis was restricted to the **8.91M transactions with available fraud labels**, identifying:

- **13,332 fraudulent transactions**
- **0.15% observed fraud rate**
- Approximately **$1.47M in observed fraud amount**

The analysis considered **fraud frequency, fraud rate, severity, and aggregate loss** rather than relying on fraud counts alone.

Cross-dimensional and advanced SQL analysis identified substantial risk concentration:

- Approximately **72% of observed fraud loss occurred online**
- The **six highest-loss merchant categories accounted for approximately 50% of total observed fraud loss**
- Cross-dimensional analysis examined relationships across **merchant category, transaction channel, geography, and time**
- Advanced SQL techniques including **window functions, ranking, Pareto analysis, rolling metrics, and temporal analysis** were used to distinguish meaningful risk concentrations from weak or potentially misleading patterns

## Technologies Used

- **PostgreSQL**
- **Python**

## Dataset

The project uses the **Transactions Fraud Datasets** dataset available on Kaggle.

[View Dataset on Kaggle](https://www.kaggle.com/datasets/computingvictor/transactions-fraud-datasets/data)

> The complete raw dataset is not stored in this repository because some source files exceed GitHub's standard file-size limits.

## Key Analytical Areas

- Executive and fraud KPIs
- Merchant category fraud analysis
- Online vs. physical transaction analysis
- Customer risk segmentation
- Geographic fraud analysis
- card based fraud analysis
- Time-based fraud analysis
- Cross-dimensional risk analysis
- Fraud-loss concentration and Pareto analysis
- Advanced SQL using window functions and ranking
- Business recommendations and analytical limitations
