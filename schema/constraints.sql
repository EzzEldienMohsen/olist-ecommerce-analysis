-- Foreign keys (added after loading, once the data was checked)
ALTER TABLE orders      ADD CONSTRAINT fk_orders_customer   FOREIGN KEY (customer_id) REFERENCES customers (customer_id);
ALTER TABLE order_items ADD CONSTRAINT fk_items_order       FOREIGN KEY (order_id)    REFERENCES orders (order_id);
ALTER TABLE order_items ADD CONSTRAINT fk_items_product     FOREIGN KEY (product_id)  REFERENCES products (product_id);
ALTER TABLE order_items ADD CONSTRAINT fk_items_seller      FOREIGN KEY (seller_id)   REFERENCES sellers (seller_id);
ALTER TABLE payments    ADD CONSTRAINT fk_payments_order    FOREIGN KEY (order_id)    REFERENCES orders (order_id);
ALTER TABLE reviews     ADD CONSTRAINT fk_reviews_order     FOREIGN KEY (order_id)    REFERENCES orders (order_id);
-- No foreign key from products to category_translation: 13 products use categories with no translation.

-- Indexes on the columns used for joins and date filters
CREATE INDEX idx_orders_customer  ON orders (customer_id);
CREATE INDEX idx_orders_purchase  ON orders (order_purchase_timestamp);
CREATE INDEX idx_items_product    ON order_items (product_id);
CREATE INDEX idx_items_seller     ON order_items (seller_id);
CREATE INDEX idx_reviews_order    ON reviews (order_id);

-- Covering index added in query 11 (performance)
CREATE INDEX idx_customer_unique  ON customers (customer_unique_id, customer_id);

VACUUM ANALYZE;
