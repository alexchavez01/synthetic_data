# Synthetic E-Commerce Data Project

This project demonstrates how to generate, clean, and analyze **synthetic e-commerce data** using Python and Google BigQuery.  
The goal was to simulate a realistic online store dataset and extract business insights through SQL queries and analysis.

## Project Overview
- **Data Generation**: Used Python (Colab) to generate synthetic customer, product, and order data.  
- **Data Cleaning**: Uploaded data to Google BigQuery and applied SQL queries to:  
  - Remove duplicates  
  - Enforce referential integrity  
  - Validate business rules (e.g., `order_date ≤ ship_date ≤ delivery_date`)  
- **Analysis**: Designed SQL queries to extract key business insights, including:  
  - Monthly revenue growth  
  - Category performance  
  - New vs. returning customer trends  
  - Shipping SLA compliance  

## Tools & Technologies
- **Python (Colab, Pandas)** → for generating and preparing synthetic datasets  
- **Google BigQuery** → for data cleaning, transformation, and analysis  
- **SQL** → for enforcing data quality and generating insights  
- **CSV Export** → cleaned data stored and shared for visualization  

## Files
- `cleaned_data.csv` → final cleaned dataset  
- `sql/` → SQL queries used in BigQuery  
- `README.md` → project documentation  

## How to Use
1. Clone this repository.  
2. Open the notebook in Google Colab to see data generation and queries.  
3. Run SQL queries in BigQuery using the provided scripts.  
4. Explore the `cleaned_data.csv` for further visualization in tools like Power BI or Tableau.  

## Insights
This project highlights how synthetic data can be leveraged to practice **data engineering and data analytics workflows**—from generation and cleaning to deriving actionable business insights.
