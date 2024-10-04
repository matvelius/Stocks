## Overview:

This proof-of-concept Stocks app was a take-home assignment for an interview process I was going through, and it deals with using the Polygon.io API to retrieve stocks data.

## Demo:

https://github.com/user-attachments/assets/e390da92-9ddf-4ca3-b2d0-a3a200ef1c8d


## Set-up:

Clone the repository and build the app to your device or using the simulator. The app will ask you to provide a valid Polygon.io API key (which you will be able to paste into the provided text box), and will not work without it.

## Notes:

The Polygon.io API does not allow a free tier user to obtain data for the current date, hence the data shown is based on the last valid market close day (the most recent week day that isn’t a holiday) and shows the daily change based on this and the prior valid market close day.

The Stock Detail view shows a line graph with data for the past 3 months.
