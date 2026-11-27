# Olist E-Commerce Analysis (SQL)

I wanted a SQL project that used more than one table and answered real business questions, so I picked the Olist dataset: about 100K orders from a Brazilian online marketplace, placed between 2016 and 2018. Everything here is done in PostgreSQL, with no Python or BI tools. Each question has its own `.sql` file.

Dataset: [Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) on Kaggle. I loaded 8 of the 9 files and skipped the geolocation table because I didn't need it. The CSVs aren't in this repo, so you'll need to download them from Kaggle.

## The questions

1. How has revenue grown month to month?
2. Which categories and sellers bring in the most money?
3. Who are the most valuable customers?
4. Do customers come back?
5. Do late deliveries hurt review scores?

SQL used along the way: JOINs, CTEs, `GROUP BY`, window functions (`LAG`, `RANK`, `DENSE_RANK`, `NTILE`, `ROW_NUMBER`, `FIRST_VALUE`), `CASE`, and date math.

## A few decisions I made

- **Delivered orders only.** Revenue is the sum of item prices on delivered orders. Canceled and unavailable orders aren't counted, and I left out freight.
- **Jan 2017 to Aug 2018 only.** The first few months of the data have almost no orders (November 2016 has none), and the last months are incomplete. Including them made the growth numbers meaningless. That leaves 96,211 delivered orders.
- **Customers by `customer_unique_id`.** The `customer_id` column changes with every order, so it can't be used to spot repeat customers.
- **One review per order.** 547 orders have more than one review, and joining them directly would count those orders twice. I kept only the latest review for each order.

## Data checks

Before the analysis I ran some basic checks (`02_data_check.sql`):

- 96,478 of 99,441 orders (97%) were delivered. The rest were shipped, canceled, unavailable, invoiced, processing, created or approved.
- 775 orders have no items. They have no price, so they add no revenue.
- 610 products (1.9%) have no category. I grouped them as `unknown`.
- In the delivery analysis, 8 delivered orders had no delivery date and 643 had no review, so I dropped them. That left 95,560 orders.

## What I found

### 1. Revenue

Total revenue over the period was R$13.18M. Monthly revenue grew from about R$112K in January 2017 to R$839K in August 2018, roughly 7.5 times.

November 2017 (Black Friday) was the peak at R$988K, about 52% higher than October. It dropped about 26% in December and recovered in January. In 2018 revenue mostly flattened, staying between R$826K and R$978K from February onward.

Growth came from more orders, not bigger ones. Revenue per order was around R$149 in January 2017, R$136 in November 2017 and R$132 in August 2018.

### 2. Categories and sellers

The biggest category is health_beauty at 9.3% of revenue, then watches_gifts (8.8%) and bed_bath_table (7.8%). The top 7 categories make up about half of revenue and the top 15 about 76%, so category revenue is fairly spread out.

Sellers are a different story. I split the 2,945 sellers into 10 equal groups by revenue. The top group (about 295 sellers) brings in 67% of all revenue, the top two groups bring in 82%, and the bottom half combined brings in only about 3%.

By state, the top categories are similar. In the first 10 states I checked (AC to MA), health_beauty is #1 in five and watches_gifts in three, and one of the two is in the top 3 everywhere. The exceptions at #1 are Acre and Amapá, which are tiny markets where each category earns under R$2.1K, so their rankings don't mean much.

### 3. Customer segments (RFM)

I scored customers on recency, frequency and spend. 97% of customers (90,315 out of 93,104) only ordered once, so I scored frequency as 1, 2 or 3+ orders instead of splitting it into five equal groups. Five equal groups would have put identical customers into different buckets.

| Segment | Customers | Share of revenue |
|---|---|---|
| Champions | 16.5% | 31.5% |
| At-risk big spenders | 14.7% | 28.8% |
| Others | 27.3% | 22.8% |
| Recent customers | 23.4% | 9.2% |
| Lost / low value | 16.5% | 4.7% |
| Loyal repeat buyers | 1.7% | 3.1% |

Champions and at-risk big spenders together are 31% of customers but about 60% of revenue. The at-risk group (13,713 customers, average spend R$276) is the obvious one to win back.

### 4. Repeat purchases

Only 3.0% of customers (2,789) placed a second order, and the median time to that second order was 29 days. The cohort table tells the same story: for the January to March 2017 cohorts, fewer than 0.5% of customers are active in any later month. For example, the January 2017 cohort had 718 customers, with 2 active in month 1 and 3 in month 6.

### 5. Delivery and reviews

6.7% of delivered orders (6,378) arrived after the estimated date. Their reviews were a lot worse:

| | Orders | Avg review | 1 to 2 star reviews |
|---|---|---|---|
| On time | 89,182 | 4.29 | 9.2% |
| Late | 6,378 | 2.27 | 62.4% |

The longer the delay, the lower the score: 3.29 stars for 1 to 3 days late, 2.10 for 4 to 7 days, and 1.70 for 8 or more days. The 8+ group is also the biggest of the late orders (2,779).

The highest late rates are in AL (20.9%), MA (17.2%), SE (15.1%), PI (13.8%) and CE (13.7%), and those states have some of the lower average scores (3.83 to 3.99). Rio de Janeiro is worth a mention too. Its late rate is 12.0%, but it has 12,172 orders, so roughly 1,450 late deliveries, more than any other state except São Paulo. São Paulo, Minas Gerais and Paraná all have late rates around 4%.

## What I'd recommend

- Fix delivery in AL, MA, SE, PI and CE, and in Rio de Janeiro because of its volume. Long delays do the most damage to reviews.
- Go after the at-risk big spenders with a win-back campaign. The median second order comes at 29 days, so the first month after a purchase is the best time to follow up.
- Work on getting customers to buy a second time. At 3%, even a small improvement would matter.
- Look at average order value. Growth has come from more orders, and the average order has actually shrunk a bit.
- Don't rely on so few sellers. The top 10% bring in two-thirds of revenue.

## Limitations

- It's two years of data from one marketplace.
- Late delivery goes with low scores, but I can't say it's the only reason for them.
- Only customers who left a review are counted in the review analysis.
- Because almost everyone ordered once, my RFM segments are mostly about recency and spend. Frequency adds very little.
- Customers who joined late in the period had less time to come back, so the repeat rate may be a bit low.
- The cohort numbers show the share of a cohort active in a given month, not a running total.

## Files

```
01_create_tables.sql
02_data_check.sql
03_revenue_trends.sql
04_category_seller_performance.sql
05_rfm_segmentation.sql
06_repeat_purchase_cohorts.sql
07_delivery_vs_reviews.sql
```

## How to run it

1. Install PostgreSQL and create a database called `olist`.
2. Download the dataset from Kaggle.
3. Run `01_create_tables.sql`, then import each CSV into its table (header on, comma delimiter).
4. Run the other files in order.

Tools: PostgreSQL, VS Code with SQLTools, pgAdmin.
