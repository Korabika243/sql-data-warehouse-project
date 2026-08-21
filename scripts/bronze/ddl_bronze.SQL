```
/*
====================================================================================
DDL Script : Create bronze tables
====================================================================================
Script purpose :
    This script creates tables in the 'bronze' schema, dropping existing tables
    if they already exist.
    Run this script to re-define the DDL structure of 'bronze' tables.
====================================================================================
*/

CREATE OR ALTER PROCEDURE Bronze.bronze_load
AS
BEGIN
    DECLARE @start_time DATETIME,
            @end_time DATETIME,
            @fwhole_time DATETIME,
            @ewhole_time DATETIME;

    BEGIN TRY
        SET @fwhole_time = GETDATE();

        PRINT '====================================';
        PRINT 'Load Bronze Layer';
        PRINT '=====================================';

        PRINT '-------------------------------------';
        PRINT 'Loading CRM Tables';
        PRINT '-------------------------------------';

        SET @start_time = GETDATE();

        PRINT '<< Truncating table: bronze.crm_cus_inf >>';

        TRUNCATE TABLE bronze.crm_cus_inf;

        PRINT '<< Inserting data into: bronze.crm_cus_inf >>';

        BULK INSERT bronze.crm_cus_inf
        FROM 'E:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\cust_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        -- SELECT * FROM bronze.crm_cus_inf;
        -- SELECT COUNT(*) FROM bronze.crm_cus_inf;

        SET @start_time = GETDATE();

        PRINT '<< Truncating table: bronze.crm_prd_inf >>';

        TRUNCATE TABLE bronze.crm_prd_inf;

        PRINT '<< Inserting data into: bronze.crm_prd_inf >>';

        BULK INSERT bronze.crm_prd_inf
        FROM 'E:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\prd_info.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        -- SELECT * FROM bronze.crm_prd_inf;
        -- SELECT COUNT(*) FROM bronze.crm_prd_inf;

        SET @start_time = GETDATE();

        PRINT '<< Truncating table: bronze.crm_sales_details >>';

        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '<< Inserting data into: bronze.crm_sales_details >>';

        BULK INSERT bronze.crm_sales_details
        FROM 'E:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm\sales_details.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        -- SELECT * FROM bronze.crm_sales_details;
        -- SELECT COUNT(*) FROM bronze.crm_sales_details;

        PRINT '********************************';
        PRINT 'Loading ERP Tables';
        PRINT '********************************';

        SET @start_time = GETDATE();

        PRINT '<< Truncating table: bronze.erp_CUST_AZ12 >>';

        TRUNCATE TABLE bronze.erp_CUST_AZ12;

        PRINT '<< Inserting data into: bronze.erp_CUST_AZ12 >>';

        BULK INSERT bronze.erp_CUST_AZ12
        FROM 'E:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\CUST_AZ12.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        -- SELECT * FROM bronze.erp_CUST_AZ12;
        -- SELECT COUNT(*) FROM bronze.erp_CUST_AZ12;

        SET @start_time = GETDATE();

        PRINT '<< Truncating table: bronze.erp_LOC_A101 >>';

        TRUNCATE TABLE bronze.erp_LOC_A101;

        PRINT '<< Inserting data into: bronze.erp_LOC_A101 >>';

        BULK INSERT bronze.erp_LOC_A101
        FROM 'E:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\LOC_A101.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        -- SELECT * FROM bronze.erp_LOC_A101;
        -- SELECT COUNT(*) FROM bronze.erp_LOC_A101;

        SET @start_time = GETDATE();

        PRINT '<< Truncating table: bronze.erp_PX_CAT_G1V2 >>';

        TRUNCATE TABLE bronze.erp_PX_CAT_G1V2;

        PRINT '<< Inserting data into: bronze.erp_PX_CAT_G1V2 >>';

        BULK INSERT bronze.erp_PX_CAT_G1V2
        FROM 'E:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp\PX_CAT_G1V2.csv'
        WITH
        (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            TABLOCK
        );

        SET @end_time = GETDATE();

        PRINT '>> Load duration: '
            + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR)
            + ' seconds';

        -- SELECT * FROM bronze.erp_PX_CAT_G1V2;
        -- SELECT COUNT(*) FROM bronze.erp_PX_CAT_G1V2;

        SET @ewhole_time = GETDATE();

        PRINT 'Whole loading duration: '
            + CAST(DATEDIFF(SECOND, @fwhole_time, @ewhole_time) AS NVARCHAR)
            + ' seconds';

    END TRY

    BEGIN CATCH
        PRINT '===============================';
        PRINT 'ERROR OCCURRED DURING BRONZE LAYER';
        PRINT 'ERROR MESSAGE: ' + ERROR_MESSAGE();
        PRINT 'ERROR NUMBER: ' + CAST(ERROR_NUMBER() AS VARCHAR);
        PRINT 'ERROR STATE: ' + CAST(ERROR_STATE() AS VARCHAR);
        PRINT '===============================';
    END CATCH
END;
```
