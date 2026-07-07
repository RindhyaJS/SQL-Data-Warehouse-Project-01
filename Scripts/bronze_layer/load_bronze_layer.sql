/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze_layer.load_bronze_layer AS
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME ,@total_start_time DATETIME,@total_end_time DATETIME;
	BEGIN TRY
		PRINT '===================================';
		PRINT 'Loading Bronze layer ';
		PRINT '===================================';

		PRINT '-----------------------------------';
		PRINT ' Loading CRM Tables ';
		PRINT '-----------------------------------';
		SET @total_start_time = GETDATE();
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table:"bronze_layer.crm_cust_info"';
		TRUNCATE TABLE bronze_layer.crm_cust_info;
		PRINT '>>Inserting Data Into:"bronze_layer.crm_cust_info"';
		BULK INSERT bronze_layer.crm_cust_info
		FROM 'C:\Users\JS Rindhya\Downloads\data_warehouse\datasets\source_crm\cust_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';

		print '----------------------------'
		
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table:"bronze_layer.crm_prd_info"';
		TRUNCATE TABLE bronze_layer.crm_prd_info;
		PRINT '>>Inserting Data Into:"bronze_layer.crm_prd_info"';
		BULK INSERT bronze_layer.crm_prd_info
		FROM 'C:\Users\JS Rindhya\Downloads\data_warehouse\datasets\source_crm\prd_info.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating Table:"bronze_layer.crm_sales_details"';
		TRUNCATE TABLE bronze_layer.crm_sales_details;

		PRINT '>>Inserting Data Into:"bronze_layer.crm_sales_details"';
		BULK INSERT bronze_layer.crm_sales_details
		FROM 'C:\Users\JS Rindhya\Downloads\data_warehouse\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR =',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		PRINT '-----------------------------------';
		PRINT ' Loading ERP Tables ';
		PRINT '-----------------------------------';
		SET @start_time = GETDATE();
		PRINT '>>Truncating Table:"bronze_layer.erp_CUST_AZ12"';
		TRUNCATE TABLE bronze_layer.erp_CUST_AZ12;
		PRINT '>>Inserting Data Into:"bronze_layer.erp_CUST_AZ12"';
		BULK INSERT  bronze_layer.erp_CUST_AZ12
		FROM 'C:\Users\JS Rindhya\Downloads\data_warehouse\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating Table:"bronze_layer.erp_LOC_A101"';
		TRUNCATE TABLE bronze_layer.erp_LOC_A101;
		PRINT '>>Inserting Data Into:"bronze_layer.erp_LOC_A101"';
		BULK INSERT bronze_layer.erp_LOC_A101
		FROM 'C:\Users\JS Rindhya\Downloads\data_warehouse\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		SET @start_time = GETDATE();
		PRINT '>>Truncating Table:"bronze_layer.erp_PX_CAT_G1V2"';
		TRUNCATE TABLE bronze_layer.erp_PX_CAT_G1V2;
		PRINT '>>Inserting Data Into:"bronze_layer.erp_PX_CAT_G1V2"';
		BULK INSERT bronze_layer.erp_PX_CAT_G1V2
		FROM 'C:\Users\JS Rindhya\Downloads\data_warehouse\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		SET @end_time = GETDATE();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'
		SET @total_end_time = GETDATE();
		PRINT 'Loading Bronze layer is compleyed ';
		PRINT ' -- Total Load Duration : ' + CAST(DATEDIFF(SECOND,@total_start_time,@total_end_time) AS NVARCHAR) + 'Seconds';
	END TRY
	BEGIN CATCH
	PRINT '===========================================';
	PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER';
	PRINT 'Error Message' + ERROR_MESSAGE();
	PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
	PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
	PRINT '===========================================';

	END CATCH
END
