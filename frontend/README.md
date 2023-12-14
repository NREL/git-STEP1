# Frontend
This is where the code for the frontend of the STEP1 webtool lives
## Frontend tutorial
- To run the frontend, open a terminal and navigate to the frontend folder via "cd git-STEP1/frontend".
- From here, run "python app.py" and click on the local host link to see the app!
## app.py
- This is the python code that allows you to create a local server by running this code and being able to see the locally hosted STEP1 webtool
- This code also creates routes throughout the application. Here are those routes:
    - /
    - /workflow
    - /location
    - /process
    - /constraints
    - /results
## Templates folder
- This is where the HTML templates live
- HTML templates are what actually is rendered on your screen when you are working with the webtool
- The HTML templates go along with the routes created in app.py
  - index.html --> /
  - workflow.html --> /workflow
  - location.html --> /location
  - process.html --> /process
  - constraints.html --> /constraints
  - results.html --> /results
