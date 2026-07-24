-- CROSS MODULE ANALYSIS:

-- 1. MCC × Online/Missing vs Physical Location
SELECT
    CASE
        WHEN UPPER(merchant_city) = 'ONLINE' THEN 'Online'
        ELSE 'Physical Location'
    END AS transaction_channel,

    mcc_description,

    COUNT(*) FILTER (
        WHERE fraud_label = 'Yes'
    ) AS fraud_transactions,

    COUNT(*) AS labeled_transactions,

    ROUND(
        100.0 * COUNT(*) FILTER (WHERE fraud_label = 'Yes')
        / NULLIF(COUNT(*), 0),
        2
    ) AS fraud_rate_pct,

    ROUND(
        COALESCE(
            SUM(amount) FILTER (WHERE fraud_label = 'Yes'),
            0
        ),
        2
    ) AS fraud_amount_lost

FROM banking.v_transactions_analytics

WHERE fraud_label IS NOT NULL
  AND mcc_description IS NOT NULL

GROUP BY
    transaction_channel,
    mcc_description

HAVING COUNT(*) FILTER (
    WHERE fraud_label = 'Yes'
) > 0

ORDER BY fraud_amount_lost DESC;

--2. Online × Hour
SELECT
    hour,
   CASE
    WHEN UPPER(merchant_city) = 'ONLINE' THEN 'Online'
    ELSE 'Physical Location'
    END AS merchant_location,
    COUNT(*) FILTER (WHERE fraud_label = 'Yes') AS fraud_transactions,
    COUNT(*) AS labeled_transactions,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE fraud_label = 'Yes')
        / NULLIF(COUNT(*), 0),
        2
    ) AS fraud_rate_pct,
    ROUND(
        COALESCE(
            SUM(amount) FILTER (WHERE fraud_label = 'Yes'),
            0
        ),
        2
    ) AS fraud_amount_lost
FROM banking.v_transactions_analytics
WHERE fraud_label IS NOT NULL
GROUP BY
    hour,
    merchant_location
ORDER BY hour, fraud_amount_lost DESC;

--MCCxhour
SELECT
    hour,
    mcc_description,
    COUNT(*) FILTER (WHERE fraud_label = 'Yes') AS fraud_transactions,
    COUNT(*) AS labeled_transactions,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE fraud_label = 'Yes')
        / NULLIF(COUNT(*), 0),
        2
    ) AS fraud_rate_pct,
    ROUND(
        COALESCE(
            SUM(amount) FILTER (WHERE fraud_label = 'Yes'),
            0
        ),
        2
    ) AS fraud_amount_lost
FROM banking.v_transactions_analytics
WHERE fraud_label IS NOT NULL
  AND hour BETWEEN 10 AND 13
  AND mcc_description IS NOT NULL
GROUP BY
    hour,
    mcc_description
HAVING COUNT(*) FILTER (WHERE fraud_label = 'Yes') > 0
ORDER BY fraud_amount_lost DESC;

-- geography x mcc
SELECT
    merchant_state,
    mcc_description,
    COUNT(*) FILTER (WHERE fraud_label = 'Yes') AS fraud_transactions,
    COUNT(*) AS labeled_transactions,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE fraud_label = 'Yes')
        / NULLIF(COUNT(*), 0),
        2
    ) AS fraud_rate_pct,
    ROUND(
        COALESCE(
            SUM(amount) FILTER (WHERE fraud_label = 'Yes'),
            0
        ),
        2
    ) AS fraud_amount_lost
FROM banking.v_transactions_analytics
WHERE fraud_label IS NOT NULL
  AND merchant_state IN ('Italy', 'Haiti', 'Tuvalu')
  AND mcc_description IS NOT NULL
GROUP BY
    merchant_state,
    mcc_description
HAVING COUNT(*) FILTER (WHERE fraud_label = 'Yes') > 0
ORDER BY fraud_amount_lost DESC;