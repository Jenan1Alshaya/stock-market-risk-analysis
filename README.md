# Stock Market Performance & Risk Analysis

Risk-adjusted performance analysis of 10 major stocks (2015–2021), built using SQL and Tableau to evaluate returns, volatility, drawdowns, and risk-adjusted performance across companies.

## Project Overview

This project analyzes historical price and volume data for 10 major companies (Apple, Amazon, Netflix, Microsoft, Google, Facebook, Tesla, Walmart, Uber, Zoom) to answer a core analytical question: **which companies delivered the strongest returns relative to the risk they carried?**

Rather than a purely descriptive dashboard, this project builds a full analytical pipeline — from data cleaning through SQL-based metric calculation to a custom-built Stock Performance Score — designed to reflect how a data analyst would approach a real risk-adjusted performance evaluation.

## Business Problem

Raw stock prices alone don't reveal which investments were genuinely well-performing. A stock with the highest return may have also carried disproportionately higher risk. This project addresses that gap by combining **return, volatility, drawdown, and Sharpe ratio** into a single, weighted, explainable performance score — enabling fair comparison across companies with very different risk profiles.

## Dataset

- 10 CSV files (one per company), each containing: `Date`, `Open`, `High`, `Low`, `Close`, `Adj Close`, `Volume`
- Combined into a unified dataset with an added `Company` column
- Data quality checks performed: missing values, duplicate records, duplicate dates per company, invalid price relationships (High/Low/Open/Close consistency), negative volume, and inconsistent trading date ranges across companies

**Note on date ranges:** Companies in this dataset have different trading history lengths (e.g., Zoom and Uber have shorter histories than Apple or Microsoft). This limits direct comparability of raw Total Return figures — annualized/risk-adjusted metrics (Sharpe ratio, volatility) provide a fairer basis for cross-company comparison.

## Data Preparation

- Combined 10 CSV files into a single dataset, deriving the `Company` column from each file name
- Converted `Date` to a consistent datetime format
- Validated data types, checked for missing values and duplicates (both full-row and per-company date duplicates)
- Verified logical price consistency (High ≥ Open/Close/Low, Low ≤ Open/Close/High, Volume ≥ 0)
- Used **Adjusted Close** (not raw Close) for all return calculations, since it accounts for dividends and stock splits and reflects the investor's actual realized return

## Tools

- **SQL (MySQL)** — data cleaning validation, metric calculation, window functions (LAG, RANK, moving averages)
- **Excel** — initial data structuring and CSV export
- **Tableau** — interactive dashboard and visualization
- **GitHub** — project documentation and version control

## SQL Analysis

All queries are available in [`sql/stock_analysis.sql`](sql/stock_analysis.sql), organized into:

- **Basic Analysis** — company counts, trading days, price/volume summaries
- **Performance** — daily/monthly/yearly/cumulative/total returns using `LAG()` and window functions
- **Risk** — annualized volatility (`STDDEV`), maximum drawdown (running peak logic), Sharpe ratio
- **Volume** — average/highest volume, day-over-day volume change
- **Comparison & Ranking** — best/worst performers by return and volatility, risk-adjusted ranking using `RANK()`
- **Stock Performance Score** — a normalized, weighted composite score (see methodology below)

## Stock Performance Score — Methodology

To rank companies fairly, a **Stock Performance Score (0–100)** was built from four normalized metrics:

| Metric | Weight | Rationale |
|---|---|---|
| Total Return | 35% | Primary measure of investment growth |
| Sharpe Ratio | 25% | Return earned per unit of risk taken |
| Volatility (inverted) | 20% | Penalizes excessive price instability |
| Maximum Drawdown (inverted) | 20% | Penalizes severe peak-to-trough losses |

Each metric was **min-max normalized** (scaled 0–1) across all 10 companies, with volatility and drawdown inverted so that lower risk contributes positively to the score. The final score = weighted sum × 100, ranked using `RANK()`.

*Note: The Sharpe Ratio assumes a risk-free rate of 0%, a simplifying assumption due to the absence of a risk-free benchmark in the dataset.*

## Dashboard

**[View the live interactive dashboard on Tableau Public →](https://public.tableau.com/app/profile/jenan.alshaya/viz/stock_dashboard_17868819046050/Dashboard1)**

The dashboard includes four focused visuals:
- **Stock Performance Score** — ranked bar chart of the composite score across all companies
- **Top 10 Returns** — total return comparison
- **Risk vs Return** — log-scale scatter plot showing the relationship between volatility and return
- **Return-to-Risk Ratio (Best Balance)** — annualized return per unit of risk

Cross-filtering is enabled: selecting a company in any chart filters the others, allowing quick company-level comparisons.

## Key Insights

Full analysis in [`insights/key_insights.md`](insights/key_insights.md). Highlights:

- **Tesla achieved the highest total return (~20,300%)**, but this coincides with the highest volatility (55%) in the dataset — a textbook high-risk, high-return profile.
- **Amazon delivered a strong 997% return with notably lower volatility (30%)** than Tesla, resulting in a more efficient risk-adjusted profile despite a lower headline return.
- **Every company experienced a maximum drawdown exceeding 28%**, with Zoom and Uber both surpassing -68% — highlighting that even top-performing stocks carried significant downside risk during the period.
- **Apple and Microsoft posted Sharpe ratios above 1.1**, among the highest in the group, despite not leading in raw returns — demonstrating efficient risk-adjusted performance.

## Findings

Higher total returns were generally, but not universally, associated with higher volatility. The Stock Performance Score reveals that **raw return rankings and risk-adjusted rankings diverge**: companies like Amazon and Apple, which don't top the return charts, rank competitively once risk is factored in — reinforcing that return alone is an incomplete measure of investment quality.

## Limitations

- Total Return % spans each company's available trading history, which varies in length — this affects direct comparability between longer-established companies and more recently listed ones (e.g., Uber, Zoom)
- Sharpe Ratio uses a simplified 0% risk-free rate assumption
- Analysis is based solely on historical price/volume data; it does not incorporate fundamental financial statements (earnings, revenue, balance sheet metrics)

## Future Improvements

- Incorporate fundamental data (P/E ratio, revenue growth) for a more holistic performance view
- Add sector/industry benchmarking to contextualize performance against peers
- Extend the dashboard with a company-level comparison page (moving averages, 52-week high/low, individual drawdown timelines)
- Automate data refresh via a scheduled SQL pipeline

## Repository Structure


