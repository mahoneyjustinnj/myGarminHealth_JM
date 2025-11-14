#!pip install garminconnect

# This cell uses the `%%writefile` magic command to create a file named `cods.py`
# in the current working directory. The content of this cell, excluding the magic
# command line itself, is written into the file.

from cods import PASSWORD, EMAIL
# print(EMAIL)
# print(PASSWORD)
import garminconnect
#from getpass import getpass
import os
# Define the path you want to set as your working directory
path = "/content"
# Set the working directory
os.chdir(path)
# Confirm it's set correctly
print("Current working directory:", os.getcwd())

print(EMAIL)
print(PASSWORD)

# run locally or in Colab
# pip install garminconnect garth pandas
from datetime import date, timedelta
import pandas as pd
from garminconnect import Garmin

# Login
g = Garmin(email=EMAIL, password=PASSWORD)
g.login()
#check if login succeeds
print(g.garth.profile)

from datetime import date, timedelta
import pandas as pd

# Define the start and end dates
start_date = date(2025, 8, 20)
end_date = date.today()

# Initialize a list to store all daily summaries
all_summaries = []

# Loop through each date
current_date = start_date
while current_date <= end_date:
    try:
        # Get heart rate summary
        hr_summary = g.get_heart_rates(current_date.isoformat())

        # Get HRV data
        hrv_data = g.get_hrv_data(current_date.isoformat())

        # Get respiration data
        respiration_data = g.get_respiration_data(current_date.isoformat())

	# Get respiration data
        sleep_data = g.get_sleep_data(current_date.isoformat())

        # Combine all data into one dictionary
        combined = {
            "summaryDate": current_date.isoformat(),
            **hr_summary,
            **hrv_data,
            **respiration_data,
            **sleep_data
        }

        # Append to the list
        all_summaries.append(combined)

    except Exception as e:
        print(f"Error fetching {current_date}: {e}")

    current_date += timedelta(days=1)

# Convert to DataFrame
df = pd.DataFrame(all_summaries)

# Save to CSV
df.to_csv("garmin_combined_summaries_from_2025-11-13.csv", index=False)




