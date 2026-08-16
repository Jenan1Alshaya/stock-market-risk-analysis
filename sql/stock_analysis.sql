DESCRIBE companies;

DESCRIBE stock_prices;

SELECT
    c.company_name,
    c.ticker_symbol,
    s.trade_date,
    s.open_price,
    s.high_price,
    s.low_price,
    s.close_price,
    s.adj_close_price,
    s.volume
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
ORDER BY s.trade_date;

SELECT COUNT(*) AS total_companies
FROM companies;

SELECT
    c.company_name,
    c.ticker_symbol,
    COUNT(*) AS trading_days
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
GROUP BY
    c.company_name,
    c.ticker_symbol
ORDER BY trading_days DESC;

SELECT
    c.company_name,
    MIN(s.trade_date) AS start_date,
    MAX(s.trade_date) AS end_date,
    COUNT(*) AS trading_days
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
GROUP BY
    c.company_name
ORDER BY start_date;

SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN trade_date IS NULL THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN open_price IS NULL THEN 1 ELSE 0 END) AS missing_open,
    SUM(CASE WHEN high_price IS NULL THEN 1 ELSE 0 END) AS missing_high,
    SUM(CASE WHEN low_price IS NULL THEN 1 ELSE 0 END) AS missing_low,
    SUM(CASE WHEN close_price IS NULL THEN 1 ELSE 0 END) AS missing_close,
    SUM(CASE WHEN adj_close_price IS NULL THEN 1 ELSE 0 END) AS missing_adj_close,
    SUM(CASE WHEN volume IS NULL THEN 1 ELSE 0 END) AS missing_volume
FROM stock_prices;

SELECT
    company_id,
    trade_date,
    COUNT(*) AS duplicate_count
FROM stock_prices
GROUP BY
    company_id,
    trade_date
HAVING COUNT(*) > 1;

SELECT *
FROM stock_prices
WHERE
    high_price < low_price
    OR high_price < open_price
    OR high_price < close_price
    OR low_price > open_price
    OR low_price > close_price;

SELECT
    c.company_name,
    MAX(s.high_price) AS highest_price,
    MIN(s.low_price) AS lowest_price
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
GROUP BY c.company_name
ORDER BY highest_price DESC;

SELECT
    c.company_name,
    ROUND(AVG(s.close_price), 2) AS avg_close_price,
    ROUND(AVG(s.volume), 0) AS avg_volume
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
GROUP BY c.company_name
ORDER BY avg_close_price DESC;

SELECT
    c.company_name,
    s.trade_date,
    s.adj_close_price,
    ROUND(
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) * 100,
        2
    ) AS daily_return_pct
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
ORDER BY
    c.company_name,
    s.trade_date;

WITH daily_returns AS (
    SELECT
        c.company_name,
        s.trade_date,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) * 100 AS daily_return_pct
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
)
SELECT
    company_name,
    MIN(daily_return_pct) AS worst_daily_return_pct,
    MAX(daily_return_pct) AS best_daily_return_pct
FROM daily_returns
GROUP BY company_name
ORDER BY best_daily_return_pct DESC;

WITH daily_returns AS (
    SELECT
        c.company_name,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) * 100 AS daily_return_pct
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
)
SELECT
    company_name,
    ROUND(AVG(daily_return_pct), 4) AS avg_daily_return_pct
FROM daily_returns
WHERE daily_return_pct IS NOT NULL
GROUP BY company_name
ORDER BY avg_daily_return_pct DESC;

WITH first_last AS (
    SELECT
        s.company_id,
        MIN(s.trade_date) AS first_date,
        MAX(s.trade_date) AS last_date
    FROM stock_prices s
    GROUP BY s.company_id
)
SELECT
    c.company_name,
    f.first_date,
    f.last_date,
    ROUND(
        (
            last_price.adj_close_price /
            first_price.adj_close_price - 1
        ) * 100,
        2
    ) AS total_return_pct
FROM first_last f
JOIN companies c
    ON f.company_id = c.company_id
JOIN stock_prices first_price
    ON first_price.company_id = f.company_id
    AND first_price.trade_date = f.first_date
JOIN stock_prices last_price
    ON last_price.company_id = f.company_id
    AND last_price.trade_date = f.last_date
ORDER BY total_return_pct DESC;

SELECT
    c.company_name,
    ROUND(AVG(s.volume), 0) AS avg_daily_volume
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
GROUP BY c.company_name
ORDER BY avg_daily_volume DESC;

SELECT
    c.company_name,
    s.trade_date,
    s.volume
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
ORDER BY s.volume DESC
LIMIT 10;

WITH daily_returns AS (
    SELECT
        s.company_id,
        c.company_name,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) AS daily_return
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
)
SELECT
    company_name,
    ROUND(
        STDDEV(daily_return) * SQRT(252) * 100,
        2
    ) AS annualized_volatility_pct
FROM daily_returns
WHERE daily_return IS NOT NULL
GROUP BY company_id, company_name
ORDER BY annualized_volatility_pct DESC;

WITH running_peaks AS (
    SELECT
        s.company_id,
        c.company_name,
        s.trade_date,
        s.adj_close_price,
        MAX(s.adj_close_price) OVER (
            PARTITION BY s.company_id
            ORDER BY s.trade_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_peak
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
),
drawdowns AS (
    SELECT
        company_id,
        company_name,
        trade_date,
        adj_close_price,
        running_peak,
        (
            adj_close_price / running_peak - 1
        ) * 100 AS drawdown_pct
    FROM running_peaks
)
SELECT
    company_name,
    ROUND(MIN(drawdown_pct), 2) AS maximum_drawdown_pct
FROM drawdowns
GROUP BY company_id, company_name
ORDER BY maximum_drawdown_pct ASC;

WITH daily_returns AS (
    SELECT
        s.company_id,
        c.company_name,
        s.trade_date,
        s.adj_close_price,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) AS daily_return
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
),
performance AS (
    SELECT
        company_id,
        company_name,
        MIN(trade_date) AS first_date,
        MAX(trade_date) AS last_date,
        STDDEV(daily_return) * SQRT(252) AS annualized_volatility
    FROM daily_returns
    WHERE daily_return IS NOT NULL
    GROUP BY company_id, company_name
)
SELECT
    p.company_name,
    ROUND(
        (
            last_price.adj_close_price /
            first_price.adj_close_price - 1
        ) * 100,
        2
    ) AS total_return_pct,
    ROUND(
        p.annualized_volatility * 100,
        2
    ) AS annualized_volatility_pct
FROM performance p
JOIN stock_prices first_price
    ON first_price.company_id = p.company_id
    AND first_price.trade_date = p.first_date
JOIN stock_prices last_price
    ON last_price.company_id = p.company_id
    AND last_price.trade_date = p.last_date
ORDER BY total_return_pct DESC;

SELECT
    c.company_name,
    s.trade_date,
    s.adj_close_price,
    ROUND(
        AVG(s.adj_close_price) OVER (
            PARTITION BY s.company_id
            ORDER BY s.trade_date
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_20d
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
ORDER BY c.company_name, s.trade_date;

SELECT
    c.company_name,
    s.trade_date,
    s.adj_close_price,
    ROUND(
        AVG(s.adj_close_price) OVER (
            PARTITION BY s.company_id
            ORDER BY s.trade_date
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_50d
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
ORDER BY c.company_name, s.trade_date;

SELECT
    c.company_name,
    s.trade_date,
    s.adj_close_price,
    ROUND(
        AVG(s.adj_close_price) OVER (
            PARTITION BY s.company_id
            ORDER BY s.trade_date
            ROWS BETWEEN 199 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS moving_avg_200d
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
ORDER BY c.company_name, s.trade_date;

WITH monthly_prices AS (
    SELECT
        s.company_id,
        c.company_name,
        DATE_FORMAT(s.trade_date, '%Y-%m') AS month,
        s.trade_date,
        s.adj_close_price,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.company_id,
                DATE_FORMAT(s.trade_date, '%Y-%m')
            ORDER BY s.trade_date
        ) AS first_day,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.company_id,
                DATE_FORMAT(s.trade_date, '%Y-%m')
            ORDER BY s.trade_date DESC
        ) AS last_day
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
)
SELECT
    company_name,
    month,
    ROUND(
        (
            MAX(CASE WHEN last_day = 1 THEN adj_close_price END) /
            MAX(CASE WHEN first_day = 1 THEN adj_close_price END)
            - 1
        ) * 100,
        2
    ) AS monthly_return_pct
FROM monthly_prices
GROUP BY
    company_id,
    company_name,
    month
ORDER BY
    company_name,
    month;

WITH yearly_prices AS (
    SELECT
        s.company_id,
        c.company_name,
        YEAR(s.trade_date) AS year,
        s.trade_date,
        s.adj_close_price,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.company_id,
                YEAR(s.trade_date)
            ORDER BY s.trade_date
        ) AS first_day,
        ROW_NUMBER() OVER (
            PARTITION BY
                s.company_id,
                YEAR(s.trade_date)
            ORDER BY s.trade_date DESC
        ) AS last_day
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
)
SELECT
    company_name,
    year,
    ROUND(
        (
            MAX(CASE WHEN last_day = 1 THEN adj_close_price END) /
            MAX(CASE WHEN first_day = 1 THEN adj_close_price END)
            - 1
        ) * 100,
        2
    ) AS yearly_return_pct
FROM yearly_prices
GROUP BY
    company_id,
    company_name,
    year
ORDER BY
    company_name,
    year;

WITH daily_returns AS (
    SELECT
        s.company_id,
        c.company_name,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) AS daily_return
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
),
stats AS (
    SELECT
        company_id,
        company_name,
        AVG(daily_return) AS avg_daily_return,
        STDDEV(daily_return) AS daily_volatility
    FROM daily_returns
    WHERE daily_return IS NOT NULL
    GROUP BY company_id, company_name
)
SELECT
    company_name,
    ROUND(
        (avg_daily_return / NULLIF(daily_volatility, 0))
        * SQRT(252),
        2
    ) AS sharpe_ratio
FROM stats
ORDER BY sharpe_ratio DESC;

WITH first_last AS (
    SELECT
        company_id,
        MIN(trade_date) AS first_date,
        MAX(trade_date) AS last_date
    FROM stock_prices
    GROUP BY company_id
),
returns AS (
    SELECT
        f.company_id,
        c.company_name,
        (
            last_price.adj_close_price /
            first_price.adj_close_price - 1
        ) * 100 AS total_return_pct
    FROM first_last f
    JOIN companies c
        ON f.company_id = c.company_id
    JOIN stock_prices first_price
        ON first_price.company_id = f.company_id
        AND first_price.trade_date = f.first_date
    JOIN stock_prices last_price
        ON last_price.company_id = f.company_id
        AND last_price.trade_date = f.last_date
)
SELECT
    company_name,
    ROUND(total_return_pct, 2) AS total_return_pct,
    RANK() OVER (
        ORDER BY total_return_pct DESC
    ) AS performance_rank
FROM returns
ORDER BY performance_rank;

SELECT
    c.company_name,
    s.trade_date,
    s.volume,
    LAG(s.volume) OVER (
        PARTITION BY s.company_id
        ORDER BY s.trade_date
    ) AS prev_volume,
    ROUND(
        (
            s.volume /
            NULLIF(LAG(s.volume) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ), 0) - 1
        ) * 100,
        2
    ) AS volume_change_pct
FROM stock_prices s
JOIN companies c
    ON s.company_id = c.company_id
ORDER BY c.company_name, s.trade_date;

WITH daily_returns AS (
    SELECT
        s.company_id,
        c.company_name,
        s.trade_date,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            )
        ) AS daily_growth_factor
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
)
SELECT
    company_name,
    trade_date,
    ROUND(
        (
            EXP(
                SUM(LN(daily_growth_factor)) OVER (
                    PARTITION BY company_id
                    ORDER BY trade_date
                    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
                )
            ) - 1
        ) * 100,
        2
    ) AS cumulative_return_pct
FROM daily_returns
WHERE daily_growth_factor IS NOT NULL
ORDER BY company_name, trade_date;

WITH daily_returns AS (
    SELECT
        s.company_id,
        c.company_name,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) AS daily_return
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
),
first_last AS (
    SELECT
        company_id,
        MIN(trade_date) AS first_date,
        MAX(trade_date) AS last_date
    FROM stock_prices
    GROUP BY company_id
),
returns AS (
    SELECT
        f.company_id,
        (
            last_price.adj_close_price /
            first_price.adj_close_price - 1
        ) * 100 AS total_return_pct
    FROM first_last f
    JOIN stock_prices first_price
        ON first_price.company_id = f.company_id
        AND first_price.trade_date = f.first_date
    JOIN stock_prices last_price
        ON last_price.company_id = f.company_id
        AND last_price.trade_date = f.last_date
),
volatility AS (
    SELECT
        company_id,
        company_name,
        STDDEV(daily_return) * SQRT(252) * 100 AS annualized_volatility_pct
    FROM daily_returns
    WHERE daily_return IS NOT NULL
    GROUP BY company_id, company_name
)
SELECT
    v.company_name,
    ROUND(r.total_return_pct, 2)          AS total_return_pct,
    ROUND(v.annualized_volatility_pct, 2) AS annualized_volatility_pct
FROM volatility v
JOIN returns r
    ON v.company_id = r.company_id
ORDER BY r.total_return_pct DESC;

WITH daily_returns AS (
    SELECT
        s.company_id,
        c.company_name,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id
                ORDER BY s.trade_date
            ) - 1
        ) AS daily_return
    FROM stock_prices s
    JOIN companies c
        ON s.company_id = c.company_id
)
SELECT
    company_name,
    ROUND(STDDEV(daily_return) * SQRT(252) * 100, 2) AS annualized_volatility_pct,
    RANK() OVER (
        ORDER BY STDDEV(daily_return) * SQRT(252) DESC
    ) AS volatility_rank
FROM daily_returns
WHERE daily_return IS NOT NULL
GROUP BY company_id, company_name
ORDER BY volatility_rank;

WITH daily_returns AS (
    SELECT
        s.company_id,
        c.company_name,
        s.trade_date,
        (
            s.adj_close_price /
            LAG(s.adj_close_price) OVER (
                PARTITION BY s.company_id ORDER BY s.trade_date
            ) - 1
        ) AS daily_return
    FROM stock_prices s
    JOIN companies c ON s.company_id = c.company_id
),
first_last AS (
    SELECT company_id, MIN(trade_date) AS first_date, MAX(trade_date) AS last_date
    FROM stock_prices GROUP BY company_id
),
total_return AS (
    SELECT
        f.company_id,
        (last_price.adj_close_price / first_price.adj_close_price - 1) * 100 AS total_return_pct
    FROM first_last f
    JOIN stock_prices first_price
        ON first_price.company_id = f.company_id AND first_price.trade_date = f.first_date
    JOIN stock_prices last_price
        ON last_price.company_id = f.company_id AND last_price.trade_date = f.last_date
),
running_peaks AS (
    SELECT
        company_id, trade_date, adj_close_price,
        MAX(adj_close_price) OVER (
            PARTITION BY company_id ORDER BY trade_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_peak
    FROM stock_prices
),
drawdown AS (
    SELECT company_id, MIN((adj_close_price / running_peak - 1) * 100) AS max_drawdown_pct
    FROM running_peaks
    GROUP BY company_id
),
stats AS (
    SELECT
        company_id, company_name,
        AVG(daily_return) AS avg_daily_return,
        STDDEV(daily_return) AS daily_volatility
    FROM daily_returns
    WHERE daily_return IS NOT NULL
    GROUP BY company_id, company_name
),
combined AS (
    SELECT
        s.company_id,
        s.company_name,
        t.total_return_pct                                              AS total_return_pct,
        (s.avg_daily_return / NULLIF(s.daily_volatility, 0)) * SQRT(252) AS sharpe_ratio,
        s.daily_volatility * SQRT(252) * 100                             AS annualized_volatility_pct,
        d.max_drawdown_pct                                               AS max_drawdown_pct
    FROM stats s
    JOIN total_return t ON s.company_id = t.company_id
    JOIN drawdown d ON s.company_id = d.company_id
),
normalized AS (
    SELECT
        company_id,
        company_name,
        total_return_pct,
        sharpe_ratio,
        annualized_volatility_pct,
        max_drawdown_pct,
        (total_return_pct - MIN(total_return_pct) OVER ()) /
            NULLIF(MAX(total_return_pct) OVER () - MIN(total_return_pct) OVER (), 0) AS norm_return,
        (sharpe_ratio - MIN(sharpe_ratio) OVER ()) /
            NULLIF(MAX(sharpe_ratio) OVER () - MIN(sharpe_ratio) OVER (), 0) AS norm_sharpe,
        1 - (annualized_volatility_pct - MIN(annualized_volatility_pct) OVER ()) /
            NULLIF(MAX(annualized_volatility_pct) OVER () - MIN(annualized_volatility_pct) OVER (), 0) AS norm_vol,
        1 - (max_drawdown_pct - MIN(max_drawdown_pct) OVER ()) /
            NULLIF(MAX(max_drawdown_pct) OVER () - MIN(max_drawdown_pct) OVER (), 0) AS norm_dd
    FROM combined
)
SELECT
    company_name,
    ROUND(total_return_pct, 2)          AS total_return_pct,
    ROUND(sharpe_ratio, 2)              AS sharpe_ratio,
    ROUND(annualized_volatility_pct, 2) AS annualized_volatility_pct,
    ROUND(max_drawdown_pct, 2)          AS max_drawdown_pct,
    ROUND(
        (norm_return * 0.35 + norm_sharpe * 0.25 + norm_vol * 0.20 + norm_dd * 0.20) * 100,
        1
    ) AS stock_performance_score,
    RANK() OVER (
        ORDER BY (norm_return * 0.35 + norm_sharpe * 0.25 + norm_vol * 0.20 + norm_dd * 0.20) DESC
    ) AS score_rank
FROM normalized
ORDER BY score_rank;
