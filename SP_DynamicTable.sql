
CREATE OR ALTER PROCEDURE [dbo].[SP_DynamicTable] (@Schema NVARCHAR(75), @Table NVARCHAR(100), @MaxCol INT = 1)
AS
BEGIN
	DECLARE @Query1 NVARCHAR(MAX);
	DECLARE @Counter INT;
	DECLARE @icount INT = 0;

--	Schema and table validation (Injection Prevention by parameterisation)

--	EXEC sp_executesql @sql, @paramDefn, @paramValues, OutputVar(if Any)
	EXEC sp_executesql N'SELECT @countOUT = count(*)
						FROM INFORMATION_SCHEMA.TABLES
						WHERE TABLE_SCHEMA = @schma AND TABLE_NAME = @tble',
						N'@schma nvarchar(75), @tble nvarchar(100), @countOUT INT OUTPUT', @schma = @Schema, @tble = @Table, @countOUT = @icount OUTPUT;

	IF @icount <> 1
		-- Table Not found -/- Duplicate Table -/- Malformed parameters
		BEGIN
			SET @Counter = 1;
			SET @Query1 = 'CREATE OR ALTER VIEW dbo.vDynamic_Table AS SELECT 404 AS Id , ''Table Not Found.'' AS Column1';
			WHILE @Counter < @MaxCol
				BEGIN
					SELECT @Query1 += ', '' '' AS Column' + CONVERT(nvarchar(10), @Counter+1)
					SET @Counter = @Counter + 1;
				END
		EXEC SP_EXECUTESQL @Query1
		-- SELECT @Query1 -- (Debug)
		END;
	ELSE
		-- Table Exits in db, Fetch metadata..
		BEGIN
			DECLARE @Query2 NVARCHAR(MAX);

			SELECT 
				@Query1 = STRING_AGG('''' + COLUMN_NAME+''' AS Column' + CONVERT(nvarchar(10), ORDINAL_POSITION), ', '),
				@Query2 = STRING_AGG('CAST(' + COLUMN_NAME+' AS VARCHAR(255)) AS Column' + CONVERT(nvarchar(10), ORDINAL_POSITION), ', '),
				@Counter = Count(COLUMN_NAME)
			FROM INFORMATION_SCHEMA.COLUMNS
			WHERE TABLE_NAME = @Table AND TABLE_SCHEMA = @Schema

			DECLARE @i INT = @MaxCol - @Counter;

			WHILE @Counter < @MaxCol
			BEGIN
				SELECT @Query1 += ', '' '' AS Column' + CONVERT(nvarchar(10), @Counter+1)
				SELECT @Query2 += ', '' '' AS Column' + CONVERT(nvarchar(10), @Counter+1)
				SET @Counter = @Counter + 1
			END

			SELECT @Query1 = 'CREATE OR ALTER VIEW dbo.vDynamic_Table AS SELECT 0 AS Id, ' + @Query1 + ' UNION SELECT ROW_NUMBER() OVER(ORDER BY (SELECT 1) ASC) AS Id, ' + @Query2 + ' FROM ' + @Schema + '.' + @Table

			EXEC SP_EXECUTESQL @Query1
			-- SELECT @Query1 -- (Debug)
		END;
END;