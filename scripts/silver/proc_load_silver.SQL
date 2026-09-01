/*
===================================================================
stored procedur: load silver layer(Bronze---> Silver)
===================================================================

script purpose:
     This stored procedure performs ETL (extraction,transform,load) process to
	 populate the 'silver' schema tabels from the 'bronze' schema.

  Action performed: 
                 -truncates silver tabels.
                 -inserts transformed and cleansed date from the 'bronze' to 'silver' tabels.

  parameters:
       None.
	   This stored procedure does not accept any parameters or return any values.


  Usage example:
     EXEC silver.silver_load;
*********************************************************************
*/
CREATE OR ALTER PROCEDURE silver.silver_load AS
BEGIN
    DECLARE @starttime DATETIME, @endtime DATETIME, @wholetimeu DATETIME, @wholetimed DATETIME;

    BEGIN TRY

        SET @wholetimeu = GETDATE();

        PRINT '====================================================';
        PRINT '<<Loading Silver Layer>>';
        PRINT '====================================================';

        PRINT '====================================================';
        PRINT '<<Loading CRM Tables>>';
        PRINT '====================================================';

        -- ============================================
        -- silver.crm_cus_inf
        -- ============================================
        SET @starttime = GETDATE();
        PRINT '<<Truncating table: silver.crm_cus_inf>>';
        TRUNCATE TABLE silver.crm_cus_inf;

        PRINT '<<Inserting clean data into: silver.crm_cus_inf>>';
        INSERT INTO silver.crm_cus_inf (
            cst_id, cst_key, cst_firstname, cst_lastname,
            cst_marital_status, cst_gndr, cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname)  AS cst_lastname,
            CASE
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                ELSE 'n/a'
            END AS cst_gndr,
            cst_create_date
        FROM (
            SELECT *,
                   ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
            FROM bronze.crm_cus_inf
        ) t
        WHERE flag_last = 1;

        SET @endtime = GETDATE();
        PRINT 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS NVARCHAR) + ' SECONDS';

        -- ============================================
        -- silver.crm_prd_inf
        -- ============================================
        SET @starttime = GETDATE();
        PRINT '<<Truncating table: silver.crm_prd_inf>>';
        TRUNCATE TABLE silver.crm_prd_inf;

        PRINT '<<Inserting clean data into: silver.crm_prd_inf>>';
        INSERT INTO silver.crm_prd_inf (
            prd_id, prd_key, cat_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt
        )
        SELECT
            prd_id,
            SUBSTRING(prd_key, 7, LEN(prd_key))                  AS prd_key,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_')          AS cat_key,
            prd_nm,
            ISNULL(prd_cost, 0)                                  AS prd_cost,
            CASE
                WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
                WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
                WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
                WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt ASC) - 1
                AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_inf;

        SET @endtime = GETDATE();
        PRINT 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS NVARCHAR) + ' SECONDS';

        -- ============================================
        -- silver.crm_sales_details
        -- ============================================
        SET @starttime = GETDATE();
        PRINT '<<Truncating table: silver.crm_sales_details>>';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '<<Inserting clean data into: silver.crm_sales_details>>';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt,
            sls_due_dt, sls_sales, sls_quantity, sls_price
        )
        SELECT
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            CASE
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            CASE
                WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
                    THEN sls_quantity * ABS(sls_price)
                ELSE sls_sales
            END AS sls_sales,
            sls_quantity,
            CASE
                WHEN sls_price <= 0 OR sls_price IS NULL
                    THEN sls_sales / NULLIF(sls_quantity, 0)
                ELSE sls_price
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @endtime = GETDATE();
        PRINT 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS NVARCHAR) + ' SECONDS';

        PRINT '*****************************************************************';
        PRINT '<<Loading ERP Tables>>';
        PRINT '*****************************************************************';

        -- ============================================
        -- silver.erp_CUST_AZ12
        -- ============================================
        SET @starttime = GETDATE();
        PRINT '<<Truncating table: silver.erp_CUST_AZ12>>';
        TRUNCATE TABLE silver.erp_CUST_AZ12;

        PRINT '<<Inserting clean data into: silver.erp_CUST_AZ12>>';
        INSERT INTO silver.erp_CUST_AZ12 (CID, BDATE, GEN)
        SELECT
            CASE
                WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
                ELSE CID
            END AS CID,
            CASE
                WHEN BDATE >= GETDATE() THEN NULL
                ELSE BDATE
            END AS BDATE,
            CASE
                WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE')   THEN 'Male'   -- FIX: was ('F','MALE'), which meant every 'M' row fell through to 'n/a'
                ELSE 'n/a'
            END AS GEN
        FROM bronze.erp_CUST_AZ12;

        SET @endtime = GETDATE();
        PRINT 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS NVARCHAR) + ' SECONDS';

        -- ============================================
        -- silver.erp_LOC_A101
        -- ============================================
        SET @starttime = GETDATE();
        PRINT '<<Truncating table: silver.erp_LOC_A101>>';
        TRUNCATE TABLE silver.erp_LOC_A101;

        PRINT '<<Inserting clean data into: silver.erp_LOC_A101>>';
        INSERT INTO silver.erp_LOC_A101 (CID, CNTRY)
        SELECT
            REPLACE(CID, '-', '') AS CID,
            CASE
                WHEN CNTRY IN ('US', 'USA')      THEN 'United States'
                WHEN CNTRY IN ('DE')              THEN 'Germany'
                WHEN CNTRY = '' OR CNTRY IS NULL  THEN 'n/a'
                ELSE TRIM(CNTRY)
            END AS CNTRY
        FROM bronze.erp_LOC_A101;

        SET @endtime = GETDATE();
        PRINT 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS NVARCHAR) + ' SECONDS';

        -- ============================================
        -- silver.erp_PX_CAT_G1V2
        -- ============================================
        SET @starttime = GETDATE();
        PRINT '<<Truncating table: silver.erp_PX_CAT_G1V2>>';
        TRUNCATE TABLE silver.erp_PX_CAT_G1V2;

        PRINT '<<Inserting clean data into: silver.erp_PX_CAT_G1V2>>';
        INSERT INTO silver.erp_PX_CAT_G1V2 (ID, CAT, SUBCAT, MAINTENANCE)
        SELECT ID, CAT, SUBCAT, MAINTENANCE
        FROM bronze.erp_PX_CAT_G1V2;

        SET @endtime = GETDATE();
        PRINT 'LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @starttime, @endtime) AS NVARCHAR) + ' SECONDS';

        SET @wholetimed = GETDATE();
        PRINT 'WHOLE LOADING DURATION: ' + CAST(DATEDIFF(SECOND, @wholetimeu, @wholetimed) AS NVARCHAR) + ' SECONDS';

    END TRY
    BEGIN CATCH
        PRINT '-----------------------------------------------------';
        PRINT 'ERROR OCCURRED DURING SILVER LAYER LOAD';
        PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER : ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'ERROR STATE  : ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '-----------------------------------------------------';
    END CATCH
END;



