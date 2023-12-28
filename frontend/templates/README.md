# HTML Templates
- HTML templates are the code that render the actual webpage. 

## index.html
- Renders the first page you see.
- Contains information about what STEP1 is and why STEP1 is important

## workflow.html
- Renders after clicking the workflow button on index.html page or clicking the back button on location.html
- Contains information about the workflow of STEP1

## location.html
- Renders after clicking the geographical inputs button on workflow.html page or clicking the back button on process.html
- Back button on this page brings you to workflow.html
- Contains inputs for:
    - Latitude
    - Longitude
    - Land Unit Price (has default land unit price)
    - Land Area

## process.html
- Renders after clicking the process inputs button on location.html page or clicking the back button on constraints.html
- Back button on this page brings you to location.html
- Contains inputs for:
    - Process Media Type
    - Maximum Process Temperature
    - Maximum Material Handling Throughput
    - Electric Bill
    - Gas Bill
    - Current Fuel Type
    - Load Profile File Input

## constraints.html
- Renders after clicking the constraints inputs button on process.html page or clicking the back button on results.html
- Back button on this page brings you to process.html
- Contains inputs for:
    - Preffered Technology
    - Maximum Investment Cost
    - Maximum Payback Period
    - Decarbonization Target
## results.html
- Renders after clicking the get results button on constraints.html page
- Back button on this page brings you to constraints.html
- Contains results of STEP1, which are:
    - Hemisphere
    - Total Cost
    - Maximum Cost Exceeded
    - State of Charge TES
    - Error
