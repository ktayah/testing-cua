# RPA Challenge Application

I want to create a more challenging version of https://rpachallenge.com's input form page. The goal is to create a demo website that I can run my computer-use agent against and test it's capabilities in more complex webpages. I want a webpage with the following challenges:

- text input based input forms
- dropdown select input
- dropdown w/ search input
- select inputs
- multiselect inputs
- random popup modals that need to be closed to continue
- data selection that requires searching for the required data in a search bar with a table. Once a search is entered, the item must be selected from the filtered list
- input data hidden in collaps-able menus that require opening
- inputs that expect a certain format, like data of birth

This page should include a mix of these inputs spread out onto multiple pages with next button between each page. Each page should represent the difficulty
of that page for the CUA. The goal is to use this webpage to test the capabilities of my agent. Please use the simplest solution possible with minimal setup. This webpage should be able to be spun up from within a docker container.

Please create this app under a new folder called "cua_challenge". Please highlight what framework or solution you will be using. The goal is lightweight, this will only be used for local testing.