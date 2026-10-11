# Analytical patterns

Six recurring shapes of business question, each applied to the Northwind sales data (July 1996 – May 1998, PostgreSQL 16). The first half says what each pattern is; the second says what the data showed and what I would do about it.

---

## What each pattern is

**Cohort retention.** Track a group that started at the same point in time — here, customers grouped by the month of their first order — and follow that same group through the months after. The group never gains members, which is what makes rows comparable. Pivoted, it gives one row per cohort and one column per month since joining.

**RFM segmentation.** Give each customer a tier from several measures considered together: recency (how long since the last order), frequency (how many orders) and monetary value (how much revenue). The combined score supports a decision, such as who to contact first.

**Sessionization.** Group scattered events into bursts, separated by a gap longer than a chosen threshold. It shows how often, and how regularly, something happens. The threshold is a business decision, not a technical one.

**Rolling metrics.** Recompute a number over a sliding window of fixed length so the trend is visible with the noise removed. Different from a session: a rolling window has a fixed size, while a session is defined by gaps.

**Funnel.** Follow a process through its stages, from start to finish, to see at which stage the loss happens.

**Pareto.** Rank items by value and accumulate their share of the total. It shows reliance, strength and weakness: how much of the whole sits on how few items. Named after Vilfredo Pareto, the Italian economist.

---

## What the data showed

### Cohort retention

**Shows:** On average, only **18%** of new customers order again the month after their first order. After that the curve does not keep falling; it levels off and fluctuates around 30%, which points to a small loyal core and a large group of one-time buyers. A first version that ignored empty cohort-months reported 44% at month one. Generating every cohort × month pair and counting the missing ones as zero corrected it to 18%.

**Action:** Concentrate retention effort on the first month after a first order, since that is where four in five customers are lost. Treat the late months (12 and beyond) with caution — those cohorts contain only a handful of customers.

### RFM segmentation

**Shows:** **20 Champions** (high recency and frequency) produce **49.46%** of revenue. **24 Lost** customers, more than a quarter of the base, produce only **5.91%**. **6 At Risk** customers — frequent buyers who have stopped ordering — hold **8.26%** of revenue.

**Action:** Call the six At Risk accounts first: Berglunds, Mère Paillarde, Blondesddsl, Victuailles, Vaffeljernet and Magazzini. They used to buy often, so winning them back is cheaper than finding new customers. Give the Champions priority account management.

### Funnel

**Shows:** 830 orders → 809 shipped (97.47%) → 772 shipped on time. **4.57%** of shipped orders were late. By year, the late rate was 4.61% in 1996, 5.39% in 1997 and **3.21%** in 1998, so fulfilment improved. The 21 unshipped orders are all from April and May 1998; they are the backlog at the data cut-off, not a fulfilment failure. By employee, Anne Dodsworth has the highest late rate (9.52%, on a small volume), and Margaret Peacock has 6.62% across 156 orders.

**Action:** Review Dodsworth's and Peacock's late orders to find the cause before drawing conclusions, since Dodsworth's rate rests on only four late orders. Do not read 1998's shipped percentage as a decline.

### Pareto

**Shows:** 80% of revenue needs **34 of 89 customers** (38%), **36 of 77 products** (47%), **15 of 29 suppliers** (52%) and **6 of 8 categories** (75%). Customers are the most concentrated dimension and categories the least. The top three customers alone hold 25.2% of revenue, and the largest supplier, Aux joyeux ecclésiastiques, accounts for 12.14%. Within Beverages, Côte de Blaye is 52.79% of the category.

**Action:** Reduce dependence on a few accounts: give the top customers dedicated account management and track their order patterns closely. Identify a backup source for the largest supplier, and check whether demand for Côte de Blaye could be met by other Beverages products.

---

## Limits of this analysis

- The data ends on 6 May 1998, so the final month and any rolling figure that includes it are incomplete.
- Small cohorts make percentages unreliable; the denominator should be read next to every rate.
- Northwind is a sample dataset. The findings demonstrate the method rather than real business conditions.
