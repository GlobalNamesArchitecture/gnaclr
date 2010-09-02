Feature: API for posting classification to gnaclr and reading information about them
  In order to be able to store and retrieve classification in Darwin Core Archive (DwCA) format
  A user should be able to put DwCA files to gnaclr, download them, query them
  So I want to implement an API which will allow this functionality

  Scenario: Adding classifications to the gnaclr
    Given there are classifications files
    When they are submitted for upload through api
    Then they will be added to the database
    And their files will be saved locally by gnaclr


  Scenario: Creating revisions of a classification
    Given there is already classification stored on gnaclr
    When a new version of this classification is submitted over api
    Then database will be updated
    And old revision will still be accessible

  Scenario: Adding a file that is not in DwCA format should fail
    Given there is a file not in DwCA format
    When a user tries to submit this file to gnaclr
    Then it should be regected
    And an error message should be returned back


