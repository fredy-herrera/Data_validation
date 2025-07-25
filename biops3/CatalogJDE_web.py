from unittest import result
import requests
from bs4 import BeautifulSoup
import pandas as pd
import openpyxl


def main():
    # List of tables to scrape
    tables = [
        "F31122",
        "F3102",
        "F31P12",
        "F31PUI02",
        "F4080",
        "F41002",
        "F41003",
        "F4101",
        "F4102",
        "F41021",
        "F4104",
        "F4108",
        "F4111",
        "F41171",
        "F4211",
        "F42199",
        "F4301",
        "F4311",
        "F4801",
        "F4801T",
        "F563003T",
        "F563112T",
        "F41112",
        "F5631P01",
        "F0401",
        "F4117",
        "F4201",
        "F4100",
        "F4105",
        "F4106",
        "F30026",
        "F43121",
        "F3111Z1",
        "F0116",
        "V0101",
        "F4101S",
        "F41061",
        "F0618",
        "F5747001",
        "F00092",
        "F55MBOM",
        "F4908",
        "F0005",
        "F0005D",
        "F42119",
        "F4140",
        "F03012",
        "F0006",
        "F30006",
        "F3002",
        "F3003",
        "F3111",
        "F3112",
        "F0101",
    ]

    all_structures = []

    # Loop through each table and extract its structure
    for table in tables:
        df = extract_table_structure(table)
        all_structures.append(df)

    # Combine all extracted structures into a single DataFrame
    tables_fields = pd.concat(all_structures, ignore_index=True)

    # Get the main table from the jde web
    schema_description = extract_jde_tables()

    result = tables_fields.merge(
        schema_description[
            ["Table", "Description"]
        ],  # Only keep necessary columns from the second one
        how="left",
        on="Table",
        suffixes=("", "_table"),  # Add a suffix in case you have 'Description' in both
    )

    result["Date"] = pd.to_datetime("today")
    result = result[
        [
            "Table",
            "Description_table",
            "Field",
            "Description",
            "Data Type",
            "Length",
            "Column",
            "Date",
        ]
    ]

    # Optionally, save the combined DataFrame to another Excel file and sheet
    with pd.ExcelWriter("catalogJDE_WEB.xlsx", engine="openpyxl") as writer:
        result.to_excel(writer, sheet_name="JDE_WEB", index=False)
    result.to_csv("catalogJDE_WEB.csv", index=False)


######################
####function extract_table_structure(table_name):
#####


# Function to extract the structure of a table from the specified URL
def extract_table_structure(table_name):
    # Build the URL with the given table name
    url = f"https://jde.erpref.com/?schema=920&system=01&table={table_name}"
    response = requests.get(url)

    # Check if the request was successful
    if response.status_code != 200:
        print(f"Failed to retrieve {table_name}")
        return pd.DataFrame()

    # Parse the HTML content using BeautifulSoup
    soup = BeautifulSoup(response.text, "html.parser")

    # Find all tables in the HTML (looking for the one with column definitions)
    tables = soup.find_all("table")
    target_table = None

    # Loop through tables to find the one with column headers
    for tbl in tables:
        headers = [th.get_text(strip=True).lower() for th in tbl.find_all("th")]
        if "column" in headers or "data item" in headers:
            target_table = tbl
            break

    # If no appropriate table is found, print a message and return an empty DataFrame
    if not target_table:
        print(f"No column structure found for {table_name}")
        return pd.DataFrame()

    # Extract headers from the target table
    headers = [th.get_text(strip=True) for th in target_table.find_all("th")]
    rows = []

    # Extract all rows except the header row
    for tr in target_table.find_all("tr")[1:]:
        cols = [td.get_text(strip=True) for td in tr.find_all("td")]
        if cols:
            cols.insert(
                0, table_name
            )  # Add the table name at the beginning of each row
            rows.append(cols)

    # Add a "Table" column to the headers
    headers.insert(0, "Table")

    # Return the extracted data as a pandas DataFrame
    return pd.DataFrame(rows, columns=headers)


##extract_table_list from jde
def extract_jde_tables(
    url="https://jde.erpref.com/?schema=920",
    skip_tables=3,
    table_column="Table",
    prefix_filter="F",
):
    # Read all HTML tables from the URL
    tables = pd.read_html(url)

    # Skip the first N tables if needed
    tables_to_use = tables[skip_tables:]

    # Combine remaining tables into a single DataFrame
    combined_df = pd.concat(tables_to_use, ignore_index=True)

    # Promote the first row to column headers
    combined_df = combined_df[1:].reset_index(drop=True)
    combined_df.columns = combined_df.iloc[0]

    # Filter rows where specified column starts with a specific prefix
    filtered_df = combined_df[
        combined_df[table_column].astype(str).str.startswith(prefix_filter)
    ]

    return filtered_df


main()
