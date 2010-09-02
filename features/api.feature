Feature: API for posting classification to gnaclr and reading information about them
  In order to be able to store and retrieve classification in Darwin Core Archive (DwCA) format
  A user should be able to put DwCA files to gnaclr, download them, query them
  So I want to implement an API which will allow this functionality

  Scenario: Adding a classification
    Given classification UUID as "11111111-1111-1111-1111-111111111111"
    And there is no classification with the UUID 
    And there is a "data_v1.tar.gz" local file
    When I upload the file through the api
    Then classification will be added
    And the file will be saved for public access

  Scenario: Creating revisions of a classification
    Given classification UUID as "11111111-1111-1111-1111-111111111111"
    And there is a classification with the UUID
    And there is a "data_v2.tar.gz" local file
    When I upload the file through the api
    Then classification will be updated
    And old revision will still be accessible

  Scenario: Adding a file that is not in DwCA format should fail
    Given classification UUID as "22222222-2222-2222-2222-222222222222"
    And there is a "not_dwca.tar.gz" local file
    When I upload the file through the api
    Then the file should be rejected

