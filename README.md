## Overview:

This proof-of-concept Stocks app focuses primarily on functionality for Stocks Overview, Stock Detail, Stocks List, and Add Stock screens, as well as app architecture (decoupling the components where possible, and organizing the code using the MVVM pattern), code quality, and handling edge cases (such as the maximum request limit of the free tier of the Polygon.io API, the complexity of dealing with valid market close dates, and more).

There are a number of things I would want to improve if I kept working on the app:

* Separating the Networking layer from the Data Service (into its own service)
* Decoupling the components further through the use of protocols
* Add much more extensive testing (ideally covering all view models and business logic / data-related code… I started adding tests but quickly realized that I had to prioritize functionality and edge cases, given the time constraints)


## Demo:

https://github.com/user-attachments/assets/e390da92-9ddf-4ca3-b2d0-a3a200ef1c8d


## Set-up:

Clone the repository and build the app to your device or using the simulator. The app will ask you to provide a valid Polygon.io API key (which you will be able to paste into the provided text box), and will not work without it.

## Assumptions:

The Polygon.io API does not allow a free tier user to obtain data for the current date, hence the data shown is based on the last valid market close day (the most recent week day that isn’t a holiday) and shows the daily change based on this and the prior valid market close day.

The Stock Detail view shows a line graph with data for the past 3 months.
