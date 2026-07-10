/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Purpose of this Procedure:
    This stored procedure performs the ETL (Extract, Transform, Load) process
    to populate the tables in the 'silver' schema using data from the
    'bronze' schema.

    Actions performed:
        - Truncates the Silver tables.
        - Inserts transformed and cleaned data from Bronze into Silver.

Parameters:
    None.
    This procedure does not take any parameters or return any values.

Example Usage:
    EXEC Silver.load_silver;
===============================================================================
*/
CREATE OR ALTER PROCEDURE silver_layer.load_silver_layer  AS
BEGIN
	DECLARE @start_time DATETIME , @end_time DATETIME ,@total_start_time DATETIME,@total_end_time DATETIME;
	BEGIN TRY
		PRINT '===================================';
		PRINT 'Loading Silver layer ';
		PRINT '===================================';

		PRINT '-----------------------------------';
		PRINT ' Loading CRM Tables ';
		PRINT '-----------------------------------';
		SET @total_start_time = GETDATE();
		SET @start_time = GETDATE();
		print '>> Truncating Table : silver_layer.crm_cust_info'
		TRUNCATE TABLE silver_layer.crm_cust_info;
		print '>> Inserting data into : silver_layer.crm_cust_info'
		INSERT INTO silver_layer.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date
		)

		select 
			cst_id,
			cst_key,
			TRIM(cst_firstname) AS cst_firstname,
			TRIM(cst_lastname) AS cst_lastname,
			CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
				 WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
				 ELSE 'n/a'
			END cst_marital_status,
			CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
				 WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
				 ELSE 'n/a'
			END cst_gndr,
			cst_create_date
		from (
			select 
				*,
				ROW_NUMBER() OVER(PARTITION BY cst_id order by cst_create_date DESC ) as ordered_date
				from silver_layer.crm_cust_info
				where cst_id is not null
		)t
		where ordered_date=1;
		set @end_time = getdate();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		SET @start_time = GETDATE();
		print '>> Truncating Table : silver_layer.crm_prd_info'
		TRUNCATE TABLE silver_layer.crm_prd_info;
		print '>> Inserting data into : silver_layer.crm_prd_info'

		insert into silver_layer.crm_prd_info(
			prd_id,
			cat_id,
			prd_key,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_dt,
			prd_end_dt
		)
		select
			prd_id,
			replace(substring(prd_key,1,5),'-','_') as cat_id, --extract category ID
			substring(prd_key,7,len(prd_key)) as prd_key,     --extract product key
			prd_nm,
			isnull(prd_cost,0) as prd_cost,
			case upper(trim(prd_line))
				 when 'M' then 'Mountain'
				 when 'R' then 'Road'
				 when 'S' then 'Other_sales'
				 when 'T' then 'Touring'
				 else 'n/a'
			end as prd_line,  --map product line codes to descriptive values
			cast(prd_start_dt as date ) as prd_start_dt,
			DATEADD(day, -1, LEAD(prd_start_dt) OVER (partition by prd_key order by prd_start_dt)) as prd_end_dt
			--cast(lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-1 
			--as date )as prd_end_dt --calculate end date as one day before the next start date
		from silver_layer.crm_prd_info;
		set @end_time = getdate();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		SET @start_time = GETDATE();
		print '>> Truncating Table : silver_layer.crm_sales_details'
		TRUNCATE TABLE silver_layer.crm_sales_details;
		print '>> Inserting data into : silver_layer.crm_sales_details'
		insert into silver_layer.crm_sales_details (
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			sls_order_dt,
			sls_ship_dt,
			sls_due_dt,
			sls_sales,
			sls_quantity,
			sls_price
	)

		select
			sls_ord_num,
			sls_prd_key,
			sls_cust_id,
			case when sls_order_dt = 0 or len(sls_order_dt) !=8 then null
				 else cast(cast (sls_order_dt as varchar) as date) 
			end as sls_order_dt,
			case when sls_ship_dt = 0 or len(sls_ship_dt) !=8 then null
				 else cast(cast (sls_ship_dt as varchar) as date) 
			end as sls_ship_dt,
			case when sls_due_dt = 0 or len(sls_due_dt) !=8 then null
				 else cast(cast (sls_due_dt as varchar) as date) 
			end as sls_due_dt,
			case when sls_sales is null or sls_sales <=0 or sls_sales!= sls_quantity*abs(sls_price)
					then sls_quantity * abs (sls_price)
				 else sls_sales
			end as sls_sales,
			sls_quantity,
			case when sls_price is null or sls_price <=0
				 then sls_sales / nullif(sls_quantity,0)
				else sls_price
			end as sls_price
		from bronze_layer.crm_sales_details;
		set @end_time = getdate();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		PRINT '-----------------------------------';
		PRINT ' Loading ERP Tables ';
		PRINT '-----------------------------------';

		SET @start_time = GETDATE();
		print '>> Truncating Table : silver_layer.erp_CUST_AZ12'
		TRUNCATE TABLE silver_layer.erp_CUST_AZ12;
		print '>> Inserting data into : silver_layer.erp_CUST_AZ12'
		insert into silver_layer.erp_CUST_AZ12 (
			cid,
			bdate,
			gen
		)
		select 
			CASE WHEN cid like 'NAS%' THEN SUBSTRING(cid,4,len(cid))
				 ELSE cid
			END cid,
			case when bdate > getdate() then null
				 else bdate
			end bdate,
			case when upper(trim(gen)) in ('F','Female') then 'Female'
				 when upper(trim(gen)) in ('M','Male') then 'Male'
				 else 'n/a'
			end gen
		from silver_layer.erp_CUST_AZ12;
		set @end_time = getdate();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		SET @start_time = GETDATE();
		print '>> Truncating Table : silver_layer.erp_LOC_A101'
		TRUNCATE TABLE silver_layer.erp_LOC_A101;
		print '>> Inserting data into : silver_layer.erp_LOC_A101'
		insert into silver_layer.erp_LOC_A101(
			CID,
			CNTRY
		)
		select 
			replace(CID,'-','')CID,
			case when trim(CNTRY) = 'DE' then 'Germany'
				 when trim(CNTRY) in ('US','USA') THEN 'United States'
				 when trim(CNTRY) = '' or CNTRY is null then 'n/a'
				 else trim(CNTRY)
			end CNTRY
		from silver_layer.erp_loc_a101;
		set @end_time = getdate();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'

		SET @start_time = GETDATE();
		print '>> Truncating Table : silver_layer.erp_PX_CAT_G1V2'
		TRUNCATE TABLE silver_layer.erp_PX_CAT_G1V2;
		print '>> Inserting data into : silver_layer.erp_PX_CAT_G1V2'
		insert into silver_layer.erp_PX_CAT_G1V2 (
			id,
			cat,
			subcat,
			maintenance
		)
		select 
			id,
			cat,
			subcat,
			maintenance
		from silver_layer.erp_PX_CAT_G1V2;
		set @end_time = getdate();
		PRINT '>> Load Duration : ' + CAST(DATEDIFF(SECOND,@start_time,@end_time) AS NVARCHAR) + 'Seconds';
		print '----------------------------'
		SET @total_end_time = GETDATE();
		print('=================================================')
		PRINT 'Loading Silver layer is compleyed ';
		PRINT ' -- Total Load Duration : ' + CAST(DATEDIFF(SECOND,@total_start_time,@total_end_time) AS NVARCHAR) + 'Seconds';
		print('=================================================')

	END TRY
	BEGIN CATCH
		PRINT '===========================================';
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER';
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '===========================================';

	END CATCH
END
