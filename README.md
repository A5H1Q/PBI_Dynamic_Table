# PBI Dynamic Table

An SQL + Power Automate based approach to show dynamic table content inside a Power BI Report. Works by first computing the maximum column from the range of input tables and then mapping those max columns in the report.
The stored procedure Creates / Alters View definition (View: dbo.vDynamic_Table) according to columns of the supplied table (Parameter-2)

## Usage
SP_DynamicTable Schema_name, Tablename, MaxColumnRange    
   
Eg: SP_DynamicTable 'dbo', 'Customers', 12

## Output Format

| Id | c1   | c2   | c3   | ... | c[m]   | ... | c(n) |
|----|------|------|------|-----|--------|-----|------|
| 0  | 'c1' | 'c2' | 'c3' |     | 'c[m]' | x   |      |
| 1  |      |      |      |     |        | x   |      |
| 2  |      |      |      |     |        | x   |      |
| 3  |      |      |      |     |        | x   |      |

(i.e, SELECT * FROM dbo.vDynamic_Table)

--	Where,    
	c = Column names of the supplied table (SP Parameter-2).   
	m = Total number of columns in the supplied table.   
	x = Indicates a white space character.   
	n = Highest column count across the range of tables (SP Parameter-3).   

## Possible cases:  

1) CASE-1 : If Supplied table exists.

```
CREATE OR ALTER VIEW dbo.vDynamic_Table AS

	SELECT	-- Generate Table Headers
		 0     AS Id
		'c1'   AS Column1,
		'c2'   AS Column2,
		'c3'   AS Column3,
		'c:'   AS Column4,
		'c[m]' AS Column5,
		'x'    AS Column6,
		'x'    AS Column7,
		'x'    AS Column8,
			:
			:
		'x'    AS Column(n)

	UNION
	SELECT	-- Generate Table Body
		ROW_NUMBER() OVER(ORDER BY (SELECT 1)) AS Id,
		CAST(c1 AS VARCHAR(255))    AS Column1,
		CAST(c2 AS VARCHAR(255))    AS Column2,
		CAST(c3 AS VARCHAR(255))    AS Column3,
		CAST(c: AS VARCHAR(255))    AS Column4,
		CAST(c[m] AS VARCHAR(255))  AS Column5,
		'x'							AS Column6,
		'x'							AS Column7,
		'x'							AS Column8,
				:
				:
		'x'                    AS Column(n)

	FROM table1
```

2) CASE-2 : If Supplied table does not exist.

```
CREATE OR ALTER VIEW dbo.vDynamic_Table AS

	SELECT	-- Generate Table Headers
		404                 AS Id
		'Table Not Found.'  AS Column1,
		'x'                 AS Column2,
		'x'                 AS Column3,
		'x'                 AS Column4,
				:
				:
		'x'                 AS Column(n),
```