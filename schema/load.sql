-- Load the Olist CSV files. Run from psql in the folder that holds the CSVs:
--   psql -d olist -f schema/load.sql
-- Adjust the paths if the CSVs are elsewhere.

\copy customers            FROM 'olist_customers_dataset.csv'          WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy orders               FROM 'olist_orders_dataset.csv'             WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy order_items          FROM 'olist_order_items_dataset.csv'        WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy payments             FROM 'olist_order_payments_dataset.csv'     WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy reviews              FROM 'olist_order_reviews_dataset.csv'      WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy products             FROM 'olist_products_dataset.csv'           WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy sellers              FROM 'olist_sellers_dataset.csv'            WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy category_translation FROM 'product_category_name_translation.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- Row counts after load:
-- customers 99,441 | orders 99,441 | order_items 112,650 | payments 103,886
-- reviews 99,224   | products 32,951 | sellers 3,095     | category_translation 71
