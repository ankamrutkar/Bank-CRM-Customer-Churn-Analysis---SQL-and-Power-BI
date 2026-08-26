use bankcrm;

-- Data Cleaning
-- duplicate Customer IDs
SELECT
    CustomerId,
    COUNT(*) AS DuplicateCount
FROM CustomerInfo
GROUP BY CustomerId
HAVING COUNT(*) > 1;

-- duplicate Bank Churn
SELECT
    CustomerId,
    COUNT(*) AS DuplicateCount
FROM Bank_Churn
GROUP BY CustomerId
HAVING COUNT(*) > 1;

-- Clean Missing Values
SELECT
    SUM(CustomerId IS NULL) AS MissingCustomerId,
    SUM(Surname IS NULL OR TRIM(Surname) = '') AS MissingSurname,
    SUM(Age IS NULL) AS MissingAge,
    SUM(GenderID IS NULL) AS MissingGenderID,
    SUM(EstimatedSalary IS NULL) AS MissingSalary,
    SUM(GeographyID IS NULL) AS MissingGeographyID,
    SUM(BankDOJ IS NULL OR TRIM(BankDOJ) = '') AS MissingBankDOJ
FROM CustomerInfo;


-- Age and Credit Score 
SELECT *
FROM Bank_Churn b
JOIN CustomerInfo c
    ON b.CustomerId = c.CustomerId
WHERE c.Age < 18
   OR c.Age > 100
   OR b.CreditScore < 350
   OR b.CreditScore > 850;
   
   
-- Valid date Format
SELECT
    CustomerId,
    BankDOJ
FROM CustomerInfo
WHERE STR_TO_DATE(BankDOJ, '%m/%d/%Y') IS NULL;

-- cleaning
SELECT
    CustomerId,
    STR_TO_DATE(BankDOJ, '%m/%d/%Y') AS CleanBankDOJ,
    YEAR(STR_TO_DATE(BankDOJ, '%m/%d/%Y')) AS JoinYear,
    MONTHNAME(STR_TO_DATE(BankDOJ, '%m/%d/%Y')) AS JoinMonth
FROM CustomerInfo;

-- Active Customer

SELECT DISTINCT
    ActiveID,
    TRIM(ActiveCategory) AS ActiveCategory
FROM ActiveCustomer
WHERE ActiveID IS NOT NULL
  AND TRIM(ActiveID) <> ''
  AND ActiveCategory IS NOT NULL
  AND TRIM(ActiveCategory) <> '';
  
  
  
-- Creating View
CREATE OR REPLACE VIEW vw_BankCustomer AS

SELECT
    c.CustomerId,
    c.Surname,
    c.Age,
    g.GenderCategory AS Gender,
    c.EstimatedSalary,
    geo.GeographyLocation AS Geography,
    c.BankDOJ,

    b.CreditScore,
    b.Tenure,
    b.Balance,
    b.NumOfProducts,

    b.HasCrCard,
    cc.Category AS CreditCardStatus,

    b.IsActiveMember,
    ac.ActiveCategory AS ActiveStatus,

    b.Exited,
    e.ExitCategory AS ExitStatus

FROM CustomerInfo c

INNER JOIN Bank_Churn b
    ON c.CustomerId = b.CustomerId

LEFT JOIN Gender g
    ON c.GenderID = g.GenderID

LEFT JOIN Geography geo
    ON c.GeographyID = geo.GeographyID

LEFT JOIN CreditCard cc
    ON b.HasCrCard = cc.CreditID

LEFT JOIN (
    SELECT DISTINCT
        ActiveID,
        ActiveCategory
    FROM ActiveCustomer
    WHERE ActiveID IS NOT NULL
      AND TRIM(ActiveID) <> ''
      AND ActiveCategory IS NOT NULL
      AND TRIM(ActiveCategory) <> ''
) ac
    ON b.IsActiveMember = ac.ActiveID

LEFT JOIN ExitCustomer e
    ON b.Exited = e.ExitID;
    
    
SELECT COUNT(*) AS TotalRows
FROM vw_BankCustomer;


SELECT
    CustomerId,
    COUNT(*) AS RecordCount
FROM vw_BankCustomer
WHERE CustomerId = 15763065
GROUP BY CustomerId;


-- Q2 
SELECT
    CustomerId,
    Surname,
    EstimatedSalary,
    BankDOJ
FROM vw_BankCustomer
WHERE YEAR(STR_TO_DATE(BankDOJ, '%m/%d/%Y')) = 2019
  AND MONTH(STR_TO_DATE(BankDOJ, '%m/%d/%Y')) IN (10, 11, 12)
ORDER BY EstimatedSalary DESC
LIMIT 5;

-- Q3
SELECT
    ROUND(AVG(NumOfProducts), 2) AS AverageProducts
FROM vw_BankCustomer
WHERE HasCrCard = 1;


-- Q4 
SELECT
    Gender,
    COUNT(*) AS TotalCustomers,
    SUM(Exited) AS ExitedCustomers,
    ROUND(
        SUM(Exited) / COUNT(*) * 100,
        2
    ) AS ChurnRate
FROM vw_BankCustomer
WHERE YEAR(STR_TO_DATE(BankDOJ, '%m/%d/%Y')) = 2019
GROUP BY Gender
ORDER BY ChurnRate DESC;

-- Q5
SELECT
    CASE
		WHEN Exited = 1 THEN 'Exited'
        WHEN Exited = 0 THEN 'Remained'
    END AS CustomerStatus,
    ROUND(AVG(CreditScore), 2) AS AverageCreditScore
FROM vw_BankCustomer
GROUP BY Exited
ORDER BY Exited;


-- Q6
SELECT
    Gender,
    ROUND(AVG(EstimatedSalary), 2) AS AverageEstimatedSalary,
    SUM(CASE
        WHEN IsActiveMember = 1 THEN 1
        ELSE 0
    END) AS ActiveAccounts
FROM vw_BankCustomer
GROUP BY Gender
ORDER BY AverageEstimatedSalary DESC;


-- Q7
SELECT
    CASE
        WHEN CreditScore BETWEEN 350 AND 449 THEN '350-449'
        WHEN CreditScore BETWEEN 450 AND 549 THEN '450-549'
        WHEN CreditScore BETWEEN 550 AND 649 THEN '550-649'
        WHEN CreditScore BETWEEN 650 AND 749 THEN '650-749'
        WHEN CreditScore BETWEEN 750 AND 850 THEN '750-850'
    END AS CreditScoreSegment,

    COUNT(*) AS TotalCustomers,

    SUM(Exited) AS ExitedCustomers,

    ROUND(
        SUM(Exited) / COUNT(*) * 100,
        2
    ) AS ExitRate

FROM vw_BankCustomer

GROUP BY
    CASE
        WHEN CreditScore BETWEEN 350 AND 449 THEN '350-449'
        WHEN CreditScore BETWEEN 450 AND 549 THEN '450-549'
        WHEN CreditScore BETWEEN 550 AND 649 THEN '550-649'
        WHEN CreditScore BETWEEN 650 AND 749 THEN '650-749'
        WHEN CreditScore BETWEEN 750 AND 850 THEN '750-850'
    END

ORDER BY ExitRate DESC;


-- Q8
SELECT
    Geography,
    COUNT(*) AS ActiveCustomers
FROM vw_BankCustomer
WHERE IsActiveMember = 1
  AND Tenure > 5
GROUP BY Geography
ORDER BY ActiveCustomers DESC;


-- Q9

SELECT
    HasCrCard,
    COUNT(*) AS TotalCustomers,
    SUM(Exited) AS ExitedCustomers,
    ROUND(
        SUM(Exited) / COUNT(*) * 100,
        2
    ) AS ChurnRate
FROM vw_BankCustomer
GROUP BY HasCrCard
ORDER BY HasCrCard;


-- Q10
SELECT
    NumOfProducts,
    COUNT(*) AS ExitedCustomers
FROM vw_BankCustomer
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY ExitedCustomers DESC;

-- Q11
SELECT
    MONTH(STR_TO_DATE(BankDOJ, '%m/%d/%Y')) AS JoinMonthNumber,
    MONTHNAME(STR_TO_DATE(BankDOJ, '%m/%d/%Y')) AS JoinMonth,
    COUNT(*) AS CustomersJoined
FROM vw_BankCustomer
GROUP BY
    MONTH(STR_TO_DATE(BankDOJ, '%m/%d/%Y')),
    MONTHNAME(STR_TO_DATE(BankDOJ, '%m/%d/%Y'))
ORDER BY JoinMonthNumber;

-- Q12

SELECT
    NumOfProducts,
    COUNT(*) AS ExitedCustomers,
    ROUND(AVG(Balance), 2) AS AverageBalance
FROM vw_BankCustomer
WHERE Exited = 1
GROUP BY NumOfProducts
ORDER BY NumOfProducts;


-- Q13

WITH RankedBalances AS (
    SELECT
        Balance,
        ROW_NUMBER() OVER (ORDER BY Balance) AS RowNum,
        COUNT(*) OVER () AS TotalRows
    FROM vw_BankCustomer
    WHERE Exited = 0
),
Quartiles AS (
    SELECT
        MAX(CASE
            WHEN RowNum = CEIL(TotalRows * 0.25)
            THEN Balance
        END) AS Q1,
        MAX(CASE
            WHEN RowNum = CEIL(TotalRows * 0.75)
            THEN Balance
        END) AS Q3
    FROM RankedBalances
    GROUP BY TotalRows
)
SELECT
    ROUND(Q1, 2) AS Q1,
    ROUND(Q3, 2) AS Q3,
    ROUND(Q3 - Q1, 2) AS IQR,
    ROUND(Q1 - (1.5 * (Q3 - Q1)), 2) AS LowerBound,
    ROUND(Q3 + (1.5 * (Q3 - Q1)), 2) AS UpperBound
FROM Quartiles;


--  Q14
DESCRIBE Geography; -- Categorical Table
DESCRIBE Gender; -- Categorical Table
DESCRIBE ActiveCustomer; -- Categorical Table
DESCRIBE ExitCustomer; -- Categorical Table
DESCRIBE CreditCard; -- Categorical Table

-- Q15
SELECT
    c.GeographyID,
    g.GenderCategory AS Gender,
    ROUND(AVG(c.EstimatedSalary), 2) AS Average_Income,
    RANK() OVER (
        PARTITION BY c.GeographyID
        ORDER BY AVG(c.EstimatedSalary) DESC
    ) AS Gender_Rank
FROM customerinfo c
JOIN gender g
    ON c.GenderID = g.GenderID
GROUP BY
    c.GeographyID,
    g.GenderCategory
ORDER BY
    c.GeographyID,
    Gender_Rank;


-- Q16
SELECT
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 50 THEN '30-50'
        WHEN Age >= 51 THEN '50+'
    END AS AgeBracket,
    COUNT(*) AS ExitedCustomers,
    ROUND(AVG(Tenure), 2) AS AverageTenure
FROM vw_BankCustomer
WHERE Exited = 1
GROUP BY
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 50 THEN '30-50'
        WHEN Age >= 51 THEN '50+'
    END
ORDER BY
    CASE
        WHEN AgeBracket = '18-30' THEN 1
        WHEN AgeBracket = '30-50' THEN 2
        WHEN AgeBracket = '50+' THEN 3
    END;

-- Q17
SELECT
    ROUND(
        (
            COUNT(*) * SUM(EstimatedSalary * Balance)
            - SUM(EstimatedSalary) * SUM(Balance)
        )
        /
        SQRT(
            (
                COUNT(*) * SUM(EstimatedSalary * EstimatedSalary)
                - POW(SUM(EstimatedSalary), 2)
            )
            *
            (
                COUNT(*) * SUM(Balance * Balance)
                - POW(SUM(Balance), 2)
            )
        ),
        4
    ) AS SalaryBalanceCorrelation
FROM vw_BankCustomer
WHERE Exited = 1;


-- Q18

SELECT 
    ROUND(
        (COUNT(*) * SUM(ci.EstimatedSalary * bc.CreditScore) - SUM(ci.EstimatedSalary) * SUM(bc.CreditScore)) 
        / 
        (SQRT(COUNT(*) * SUM(ci.EstimatedSalary * ci.EstimatedSalary) - SUM(ci.EstimatedSalary) * SUM(ci.EstimatedSalary)) 
        * SQRT(COUNT(*) * SUM(bc.CreditScore * bc.CreditScore) - SUM(bc.CreditScore) * SUM(bc.CreditScore)))
    , 4) AS Correlation_Salary_CreditScore
FROM 
    vw_BankCustomer ci
JOIN 
    Bank_Churn bc ON ci.CustomerId = bc.CustomerId;

    
-- Q19

SELECT
    CreditScoreBucket,
    ChurnedCustomers,
    RANK() OVER (
        ORDER BY ChurnedCustomers DESC
    ) AS ChurnRank
FROM
(
    SELECT
        CASE
            WHEN CreditScore BETWEEN 350 AND 449 THEN '350-449'
            WHEN CreditScore BETWEEN 450 AND 549 THEN '450-549'
            WHEN CreditScore BETWEEN 550 AND 649 THEN '550-649'
            WHEN CreditScore BETWEEN 650 AND 749 THEN '650-749'
            WHEN CreditScore BETWEEN 750 AND 850 THEN '750-850'
        END AS CreditScoreBucket,
        COUNT(*) AS ChurnedCustomers
    FROM vw_BankCustomer
    WHERE Exited = 1
    GROUP BY
        CASE
            WHEN CreditScore BETWEEN 350 AND 449 THEN '350-449'
            WHEN CreditScore BETWEEN 450 AND 549 THEN '450-549'
            WHEN CreditScore BETWEEN 550 AND 649 THEN '550-649'
            WHEN CreditScore BETWEEN 650 AND 749 THEN '650-749'
            WHEN CreditScore BETWEEN 750 AND 850 THEN '750-850'
        END
) AS ChurnData
ORDER BY ChurnRank;



-- Q20
SELECT
    AgeBucket,
    CreditCardCustomers
FROM
(
    SELECT
        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 50 THEN '30-50'
            WHEN Age >= 51 THEN '50+'
        END AS AgeBucket,
        COUNT(*) AS CreditCardCustomers
    FROM vw_BankCustomer
    WHERE HasCrCard = 1
    GROUP BY
        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 50 THEN '30-50'
            WHEN Age >= 51 THEN '50+'
        END
) AS AgeCreditCard
WHERE CreditCardCustomers <
(
    SELECT AVG(CreditCardCustomers)
    FROM
    (
        SELECT
            CASE
                WHEN Age BETWEEN 18 AND 30 THEN '18-30'
                WHEN Age BETWEEN 31 AND 50 THEN '30-50'
                WHEN Age >= 51 THEN '50+'
            END AS AgeBucket,
            COUNT(*) AS CreditCardCustomers
        FROM vw_BankCustomer
        WHERE HasCrCard = 1
        GROUP BY
            CASE
                WHEN Age BETWEEN 18 AND 30 THEN '18-30'
                WHEN Age BETWEEN 31 AND 50 THEN '30-50'
                WHEN Age >= 51 THEN '50+'
            END
    ) AS AverageData
);


-- Q21

SELECT
    Geography AS Location,
    COUNT(CASE
        WHEN Exited = 1 THEN 1
    END) AS ChurnedCustomers,
    ROUND(AVG(Balance), 2) AS AverageBalance,
    RANK() OVER (
        ORDER BY COUNT(CASE
            WHEN Exited = 1 THEN 1
        END) DESC
    ) AS ChurnRank,
    RANK() OVER (
        ORDER BY AVG(Balance) DESC
    ) AS BalanceRank
FROM vw_BankCustomer
GROUP BY Geography
ORDER BY ChurnRank;


-- Q22
SELECT
    CustomerId,
    Surname,
    CustomerID_Surname
FROM vw_BankCustomer
LIMIT 10;

-- Q23
SELECT
    CustomerId,
    Exited,
    ExitCategory
FROM vw_BankChurn_ExitCategory
LIMIT 10;

-- Q24
SELECT
    SUM(CASE WHEN Gender IS NULL OR TRIM(Gender) = '' THEN 1 ELSE 0 END) AS MissingGender,
    SUM(CASE WHEN CreditCardStatus IS NULL OR TRIM(CreditCardStatus) = '' THEN 1 ELSE 0 END) AS MissingCreditCardStatus,
    SUM(CASE WHEN ActiveStatus IS NULL OR TRIM(ActiveStatus) = '' THEN 1 ELSE 0 END) AS MissingActiveStatus,
    SUM(CASE WHEN ExitStatus IS NULL OR TRIM(ExitStatus) = '' THEN 1 ELSE 0 END) AS MissingExitStatus
FROM vw_BankCustomer;

use bankcrm;
-- Q25
SELECT
    CustomerId,
    Surname,
    ActiveStatus
FROM vw_BankCustomer
WHERE LOWER(Surname) LIKE '%on';


-- Q26

SELECT
    COUNT(*) AS DisruptedCustomers,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM vw_BankCustomer),
        2
    ) AS DisruptionPercentage
FROM vw_BankCustomer
WHERE Exited = 1
  AND IsActiveMember = 1;
  
  
  -- Subjective Questions ---
  
  -- Q1
  SELECT 
	CASE WHEN Tenure <= 5 THEN 'New / Mid Tenure' 
    ELSE 'Long Term' END AS CustomerTenureGroup, 
    COUNT(*) AS TotalCustomers, 
    ROUND(AVG(Balance), 2) AS AverageBalance, 
    ROUND(AVG(NumOfProducts), 2) AS AverageProducts, 
    ROUND(AVG(IsActiveMember) * 100, 2) AS ActiveRate, 
    ROUND(AVG(Exited) * 100, 2) AS ChurnRate 
FROM vw_BankCustomer 
GROUP BY 
	CASE 
		WHEN Tenure <= 5 THEN 'New / Mid Tenure' 
        ELSE 'Long Term' 
	END;


-- Q2
SELECT
    NumOfProducts,
    HasCrCard,
    COUNT(*) AS CustomerCount,
    ROUND(AVG(Exited) * 100, 2) AS ChurnRate
FROM vw_BankCustomer
GROUP BY
    NumOfProducts,
    HasCrCard
ORDER BY CustomerCount DESC;


-- Q3 

SELECT
    Geography,
    COUNT(*) AS TotalCustomers,
    SUM(IsActiveMember) AS ActiveCustomers,
    SUM(Exited) AS ChurnedCustomers,
    ROUND(AVG(EstimatedSalary), 2) AS AverageSalary,
    ROUND(AVG(Balance), 2) AS AverageBalance,
    ROUND(AVG(Exited) * 100, 2) AS ChurnRate
FROM vw_BankCustomer
GROUP BY Geography
ORDER BY ChurnRate DESC;


-- Q4

SELECT
    CASE
        WHEN Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '50+'
    END AS AgeGroup,
    Geography,
    COUNT(*) AS TotalCustomers,
    SUM(Exited) AS ChurnedCustomers,
    ROUND(AVG(Exited) * 100, 2) AS ChurnRate,
    ROUND(AVG(Balance), 2) AS AverageBalance,
    ROUND(AVG(CreditScore), 2) AS AverageCreditScore,
    ROUND(AVG(IsActiveMember) * 100, 2) AS ActiveRate
FROM vw_BankCustomer
GROUP BY
    AgeGroup,
    Geography
ORDER BY ChurnRate DESC;


-- Q7


SELECT 
    CASE 
        WHEN bc.Exited = 1 THEN 'Exited (Left Bank)'
        WHEN bc.Exited = 0 THEN 'Retained (Stayed)'
    END AS CustomerStatus,
    COUNT(*) AS TotalCustomers,
    ROUND(AVG(bc.Age), 0) AS AvgAge,
    ROUND(AVG(bc.Balance), 2) AS AvgBalance,
    ROUND(AVG(bc.CreditScore), 0) AS AvgCreditScore,
    ROUND((SUM(bc.IsActiveMember) / COUNT(*)) * 100, 2) AS ActivePercentage
FROM 
    vw_BankCustomer bc
GROUP BY 
    bc.Exited;
  
  
  
-- Q8

SELECT 
    CASE 
        WHEN bc.Exited = 1 THEN 'Left Bank (Churned)'
        WHEN bc.Exited = 0 THEN 'Stayed (Retained)'
    END AS CustomerStatus,
    COUNT(*) AS CustomerCount,
    ROUND(AVG(bc.Tenure), 2) AS AvgTenure,
    ROUND(AVG(bc.NumOfProducts), 2) AS AvgProducts,
    ROUND((SUM(bc.IsActiveMember) / COUNT(*)) * 100, 2) AS ActivePercentage,
    ROUND(AVG(bc.EstimatedSalary), 2) AS AvgSalary
FROM 
    vw_BankCustomer bc
GROUP BY 
    bc.Exited;
    
    
-- Q9

SELECT 
    CASE 
        WHEN ci.Age BETWEEN 18 AND 30 THEN 'Young Adult (18-30)'
        WHEN ci.Age BETWEEN 31 AND 50 THEN 'Adult (31-50)'
        WHEN ci.Age > 50 THEN 'Senior (50+)'
    END AS AgeSegment,
    CASE
        WHEN ci.Balance = 0 THEN 'Zero Balance'
        WHEN ci.Balance > 0 AND ci.Balance <= 100000 THEN 'Low-Medium Balance'
        WHEN ci.Balance > 100000 THEN 'High Balance'
    END AS BalanceSegment,
    COUNT(*) AS CustomerCount,
    ROUND((SUM(ci.Exited) / COUNT(*)) * 100, 2) AS ChurnRatePercentage
FROM 
    vw_BankCustomer ci
GROUP BY 
    AgeSegment,BalanceSegment
ORDER BY AgeSegment,BalanceSegment;

