DECLARE
    -- Declare order variables
    v_order_id NUMBER;
    v_customer_id NUMBER := :customer_id;
    v_order_date DATE := SYSDATE;
    v_total_amount NUMBER := 0;
    v_status VARCHAR2(20);
    v_payment_status VARCHAR2(20);
    v_shipping_status VARCHAR2(20);
    v_order_priority VARCHAR2(20);
    v_shipping_address VARCHAR2(200);
    v_billing_address VARCHAR2(200);
    v_customer_type VARCHAR2(20);
    v_shipping_cost NUMBER := 0;
    v_tax_rate NUMBER := 0.05;
    v_tax_amount NUMBER := 0;
    v_is_expedited BOOLEAN := FALSE;
    v_loyalty_points_used NUMBER := 0;
    v_loyalty_discount NUMBER := 0;
    v_coupon_code VARCHAR2(20);
    v_coupon_discount NUMBER := 0;
    v_is_coupon_valid BOOLEAN := FALSE;

    -- Declare variables for line items
    CURSOR c_order_items IS
        SELECT product_id, quantity
        FROM order_items_temp
        WHERE customer_id = v_customer_id;

    v_product_id NUMBER;
    v_quantity NUMBER;
    v_stock_available NUMBER;
    v_product_price NUMBER;
    v_line_amount NUMBER;
    v_discount NUMBER := 0;
    v_loyalty_points_earned NUMBER := 0;
    v_product_category VARCHAR2(50);
    v_category_discount NUMBER := 0;

    -- Declare exception for handling stock availability
    e_out_of_stock EXCEPTION;
    e_invalid_customer EXCEPTION;
    e_invalid_coupon EXCEPTION;
    e_invalid_shipping_address EXCEPTION;
    e_insufficient_loyalty_points EXCEPTION;
BEGIN
    -- Validate customer
    SELECT COUNT(*) INTO v_status FROM customers WHERE customer_id = v_customer_id;
    IF v_status = 0 THEN
        RAISE e_invalid_customer;
    END IF;

    -- Fetch customer details
    SELECT customer_type, billing_address, shipping_address INTO v_customer_type, v_billing_address, v_shipping_address
    FROM customers
    WHERE customer_id = v_customer_id;

    -- Validate shipping address
    IF v_shipping_address IS NULL THEN
        RAISE e_invalid_shipping_address;
    END IF;

    -- Create order
    SELECT order_seq.NEXTVAL INTO v_order_id FROM dual;
    INSERT INTO orders (order_id, customer_id, order_date, total_amount, status, payment_status, shipping_status, order_priority, shipping_address, billing_address)
    VALUES (v_order_id, v_customer_id, v_order_date, v_total_amount, 'Pending', 'Unpaid', 'Not Shipped', 'Normal', v_shipping_address, v_billing_address);

    -- Process each line item
    FOR r_item IN c_order_items LOOP
        v_product_id := r_item.product_id;
        v_quantity := r_item.quantity;

        -- Validate stock availability
        SELECT stock_quantity INTO v_stock_available FROM products WHERE product_id = v_product_id;
        IF v_stock_available < v_quantity THEN
            RAISE e_out_of_stock;
        END IF;

        -- Get product price and category
        SELECT price, category INTO v_product_price, v_product_category FROM products WHERE product_id = v_product_id;

        -- Apply category-based discount
        IF v_product_category = 'Electronics' THEN
            v_category_discount := 0.05; -- 5% discount for electronics
        ELSIF v_product_category = 'Clothing' THEN
            v_category_discount := 0.1; -- 10% discount for clothing
        ELSE
            v_category_discount := 0;
        END IF;
        v_product_price := v_product_price * (1 - v_category_discount);

        -- Calculate line amount
        v_line_amount := v_quantity * v_product_price;
        v_total_amount := v_total_amount + v_line_amount;

        -- Insert line item
        INSERT INTO order_items (order_id, product_id, quantity, line_amount)
        VALUES (v_order_id, v_product_id, v_quantity, v_line_amount);

        -- Update product stock
        UPDATE products SET stock_quantity = stock_quantity - v_quantity
        WHERE product_id = v_product_id;
    END LOOP;

    -- Apply discount based on total amount (business logic)
    IF v_total_amount > 500 THEN
        v_discount := v_total_amount * 0.1; -- 10% discount for orders above 500
        v_total_amount := v_total_amount - v_discount;
    END IF;

    -- Apply loyalty points if used
    IF v_loyalty_points_used > 0 THEN
        SELECT loyalty_points INTO v_loyalty_points_earned FROM customers WHERE customer_id = v_customer_id;
        IF v_loyalty_points_earned < v_loyalty_points_used THEN
            RAISE e_insufficient_loyalty_points;
        END IF;
        v_loyalty_discount := v_loyalty_points_used * 0.01; -- Each point gives 1% discount
        v_total_amount := v_total_amount - v_loyalty_discount;

        -- Update loyalty points
        UPDATE customers SET loyalty_points = loyalty_points - v_loyalty_points_used WHERE customer_id = v_customer_id;
    END IF;

    -- Apply coupon discount if applicable
    IF v_coupon_code IS NOT NULL THEN
        SELECT COUNT(*) INTO v_status FROM coupons WHERE coupon_code = v_coupon_code AND expiry_date > SYSDATE;
        IF v_status = 0 THEN
            RAISE e_invalid_coupon;
        END IF;

        SELECT discount_percentage INTO v_coupon_discount FROM coupons WHERE coupon_code = v_coupon_code;
        v_coupon_discount := v_total_amount * (v_coupon_discount / 100);
        v_total_amount := v_total_amount - v_coupon_discount;
    END IF;

    -- Calculate tax
    v_tax_amount := v_total_amount * v_tax_rate;
    v_total_amount := v_total_amount + v_tax_amount;

    -- Calculate shipping cost
    IF v_is_expedited THEN
        v_shipping_cost := 20; -- Expedited shipping cost
        v_order_priority := 'High';
    ELSE
        v_shipping_cost := 10; -- Standard shipping cost
        v_order_priority := 'Normal';
    END IF;
    v_total_amount := v_total_amount + v_shipping_cost;

    -- Update order total amount and other details
    UPDATE orders SET total_amount = v_total_amount, order_priority = v_order_priority WHERE order_id = v_order_id;

    -- Commit transaction
    COMMIT;

    -- Display success message
    DBMS_OUTPUT.PUT_LINE('Order submitted successfully with Order ID: ' || v_order_id);
    DBMS_OUTPUT.PUT_LINE('Total Amount (after discount, tax, and shipping): ' || v_total_amount);

EXCEPTION
    WHEN e_out_of_stock THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Order failed: Insufficient stock for Product ID ' || v_product_id);
    WHEN e_invalid_customer THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Order failed: Invalid customer ID.');
    WHEN e_invalid_coupon THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Order failed: Invalid or expired coupon code.');
    WHEN e_invalid_shipping_address THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Order failed: Invalid shipping address.');
    WHEN e_insufficient_loyalty_points THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Order failed: Insufficient loyalty points.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Order failed due to unexpected error: ' || SQLERRM);
END;
