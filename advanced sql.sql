--Pareto analysis of fraud loss by MCC
WITH mcc_fraud AS (
    SELECT
        mcc_description,
        COUNT(*) FILTER (WHERE fraud_label = 'Yes') AS fraud_transactions,
        ROUND(
            SUM(amount) FILTER (WHERE fraud_label = 'Yes'),
            2
        ) AS fraud_amount_lost
    FROM banking.v_transactions_analytics
    WHERE fraud_label IS NOT NULL
      AND mcc_description IS NOT NULL
    GROUP BY mcc_description
)

SELECT
    mcc_description,
    fraud_transactions,
    fraud_amount_lost,

    ROUND(
        100.0 * fraud_amount_lost
        / SUM(fraud_amount_lost) OVER (),
        2
    ) AS fraud_loss_pct,

    ROUND(
        100.0 * SUM(fraud_amount_lost) OVER (
            ORDER BY fraud_amount_lost DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / SUM(fraud_amount_lost) OVER (),
        2
    ) AS cumulative_fraud_loss_pct

FROM mcc_fraud
WHERE fraud_transactions > 0
ORDER BY fraud_amount_lost DESC;

--The top five fraud-loss merchant categories separately for Online and Physical transactions?
WITH mcc_channel AS (
    SELECT
        CASE
            WHEN UPPER(merchant_city) = 'ONLINE' THEN 'Online'
            ELSE 'Physical Location'
        END AS transaction_channel,

        mcc_description,

        COUNT(*) FILTER (
            WHERE fraud_label = 'Yes'
        ) AS fraud_transactions,

        ROUND(
            SUM(amount) FILTER (
                WHERE fraud_label = 'Yes'
            ),
            2
        ) AS fraud_amount_lost

    FROM banking.v_transactions_analytics

    WHERE fraud_label IS NOT NULL
      AND mcc_description IS NOT NULL

    GROUP BY
        transaction_channel,
        mcc_description
),

ranked_mcc AS (
    SELECT
        *,
        DENSE_RANK() OVER (
            PARTITION BY transaction_channel
            ORDER BY fraud_amount_lost DESC
        ) AS risk_rank

    FROM mcc_channel

    WHERE fraud_transactions > 0
)

SELECT *
FROM ranked_mcc
WHERE risk_rank <= 5
ORDER BY transaction_channel, risk_rank;

--month over month analysis
WITH monthly_fraud AS (
    SELECT
        year,
        month,

        COUNT(*) FILTER (
            WHERE fraud_label = 'Yes'
        ) AS fraud_transactions,

        ROUND(
            SUM(amount) FILTER (
                WHERE fraud_label = 'Yes'
            ),
            2
        ) AS fraud_amount_lost

    FROM banking.v_transactions_analytics

    WHERE fraud_label IS NOT NULL

    GROUP BY year, month
),

monthly_comparison AS (
    SELECT
        *,

        LAG(fraud_transactions) OVER (
            ORDER BY year, month
        ) AS previous_month_fraud_transactions,

        LAG(fraud_amount_lost) OVER (
            ORDER BY year, month
        ) AS previous_month_fraud_amount

    FROM monthly_fraud
)

SELECT
    year,
    month,
    fraud_transactions,
    fraud_amount_lost,


    ROUND(
        100.0 *
        (fraud_transactions - previous_month_fraud_transactions)
        / NULLIF(previous_month_fraud_transactions, 0),
        2
    ) AS fraud_count_mom_change_pct,

    ROUND(
        100.0 *
        (fraud_amount_lost - previous_month_fraud_amount)
        / NULLIF(previous_month_fraud_amount, 0),
        2
    ) AS fraud_amount_mom_change_pct

FROM monthly_comparison

ORDER BY year, month;

--Rolling 3 month fraud analysis
WITH monthly_fraud AS (
    SELECT
        year,
        month,

        COUNT(*) FILTER (
            WHERE fraud_label = 'Yes'
        ) AS fraud_transactions,

        ROUND(
            SUM(amount) FILTER (
                WHERE fraud_label = 'Yes'
            ),
            2
        ) AS fraud_amount_lost

    FROM banking.v_transactions_analytics

    WHERE fraud_label IS NOT NULL

    GROUP BY year, month
)

SELECT
    year,
    month,
    fraud_transactions,
    fraud_amount_lost,

    ROUND(
        AVG(fraud_transactions) OVER (
            ORDER BY year, month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_avg_fraud_count,

    ROUND(
        AVG(fraud_amount_lost) OVER (
            ORDER BY year, month
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_avg_fraud_amount

FROM monthly_fraud

ORDER BY year, month;

--Running cumulative fraud loss over time
WITH monthly_fraud AS (
    SELECT
        year,
        month,

        COUNT(*) FILTER (
            WHERE fraud_label = 'Yes'
        ) AS fraud_transactions,

        ROUND(
            SUM(amount) FILTER (
                WHERE fraud_label = 'Yes'
            ),
            2
        ) AS fraud_amount_lost

    FROM banking.v_transactions_analytics

    WHERE fraud_label IS NOT NULL

    GROUP BY year, month
)

SELECT
    year,
    month,
    fraud_transactions,
    fraud_amount_lost,

    SUM(fraud_transactions) OVER (
        ORDER BY year, month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_fraud_transactions,

    ROUND(
        SUM(fraud_amount_lost) OVER (
            ORDER BY year, month
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ),
        2
    ) AS cumulative_fraud_amount

FROM monthly_fraud

ORDER BY year, month;