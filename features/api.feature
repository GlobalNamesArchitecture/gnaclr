Feature: API for posting classification to Gnaclr and reading information about them
  In order to be able to store and retrieve classification in Darwin Core Archive (DwCA) format
  A user should be able to put DwCA files to Gnaclr, download them, query them
  So I want to implement an API which will allow this functionality

  Scenario: Adding a classification
    Given UUID "11111111-1111-1111-1111-111111111111"
    And no classification with the UUID 
    And a "data_v1.tar.gz" local file
    When I upload the file through the API
    Then classification will be added
    And the file will be saved for public access

  Scenario: Creating revisions of a classification
    Given UUID "11111111-1111-1111-1111-111111111111"
    And a classification with the UUID
    And a "data_v2.tar.gz" local file
    When I upload the file through the API
    Then classification will be updated
    And the file will be saved for public access
    And old revision will still be accessible

  Scenario: Adding a file that is not in DwCA format should fail
    Given UUID "22222222-2222-2222-2222-222222222222"
    And a "not_dwca.tar.gz" local file
    When I upload the file through the API
    Then the file should be rejected

  Scenario: Searching API by a metadata words
    Given UUID "11111111-1111-1111-1111-111111111111"
    And a classification with the UUID
    When I search for "Classification" using API
    Then I find json data about this classification
    And I find xml data about this classification
    When I search for "TERM*NOT*IN*DB" using API
    Then I find no classifications
  
  Scenario: Searching API by a metadata words with revisions flag
    Given UUID "11111111-1111-1111-1111-111111111111"
    And several revisions of a classification with the UUID
    When I search for "Classification" using API with revisions flag
    Then I get data about revisions

  Scenario: Getting a classification info by id from API
    Given UUID "11111111-1111-1111-1111-111111111111"
    And a classification with the UUID
    And several revisions of a classification with the UUID
    When I query API for the classification with the id
    Then I find json data about this classification
    And I find xml data about this classification
    And I get data about revisions

  Scenario: Checking a classification info by UUID from API
    Given UUID "11111111-1111-1111-1111-111111111111"
    And a classification with the UUID
    And several revisions of a classification with the UUID
    When I query API for the classification with the UUID
    Then I find json data about this classification
    And I find xml data about this classification
    And I get data about revisions
