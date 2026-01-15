# Example: Using Test Data Files with CUA Agent
#
# This file shows how to load and use the test data JSON files
# with your Elixir CUA agent.

defmodule CuaApp.ChallengeTest do
  @moduledoc """
  Helper module for running CUA Challenge tests with predefined data files.
  """

  @test_data_dir Path.join([__DIR__, "test_data"])

  @doc """
  Loads a test data file and returns the parsed JSON.

  ## Examples

      iex> CuaApp.ChallengeTest.load_test_data(1)
      %{"test_id" => "scenario_001", ...}
  """
  def load_test_data(scenario_number) when scenario_number in 1..3 do
    file_path = Path.join(__DIR__, "test_data_#{scenario_number}.json")

    case File.read(file_path) do
      {:ok, content} -> Jason.decode!(content)
      {:error, reason} -> raise "Failed to load test data: #{reason}"
    end
  end

  @doc """
  Builds a task description from test data for the agent to execute.
  """
  def build_task_description(test_data) do
    """
    Complete the CUA Challenge form at http://cua-challenge with the following information.
    Handle all format conversions as needed (dates, phone numbers, etc.).

    === PAGE 1: BASIC INFORMATION ===
    First Name: #{test_data["page1"]["first_name"]}
    Last Name: #{test_data["page1"]["last_name"]}
    Email: #{test_data["page1"]["email"]}
    Date of Birth: #{test_data["page1"]["date_of_birth"]} (convert to YYYY-MM-DD format)
    Country: #{test_data["page1"]["country"]} (select matching dropdown value)
    Phone Number: #{test_data["page1"]["phone_number"]} (convert to XXX-XXX-XXXX format)

    === PAGE 2: ADDITIONAL DETAILS ===
    Street Address: #{test_data["page2"]["street_address"]}
    City: #{test_data["page2"]["city"]}
    Zip Code: #{test_data["page2"]["zip_code"]}
    Employment Status: #{test_data["page2"]["employment_status"]}
    Skills: Select all of these: #{Enum.join(test_data["page2"]["skills"], ", ")}
    Years of Experience: #{test_data["page2"]["years_of_experience"]}
    Preferred Contact Method: #{test_data["page2"]["preferred_contact_method"]}

    === PAGE 3: ADVANCED SELECTION ===
    Company: #{test_data["page3"]["company"]["hint"]}
    Emergency Contact Section (MUST EXPAND FIRST):
      - Name: #{test_data["page3"]["emergency_contact"]["name"]}
      - Phone: #{test_data["page3"]["emergency_contact"]["phone"]} (convert to XXX-XXX-XXXX)
      - Relationship: #{test_data["page3"]["emergency_contact"]["relationship"]}
    Product Selection: #{test_data["page3"]["product"]["search_hint"]}

    === PAGE 4: FINAL CHALLENGE ===
    Project Type: #{test_data["page4"]["project_type"]} (select this FIRST)
    Framework: #{test_data["page4"]["framework"]["hint"]} (field appears after project type)

    Technical Requirements Section (MUST EXPAND FIRST):
      - Features: Select at least 3: #{Enum.join(test_data["page4"]["features"], ", ")}
      - Budget: $#{test_data["page4"]["budget"]}

    Team Information Section (MUST EXPAND FIRST):
      - Team Size: #{test_data["page4"]["team"]["size"]}
      - Project Manager: #{test_data["page4"]["team"]["project_manager"]}

    Vendor Selection: #{test_data["page4"]["vendor"]["search_hint"]}
    Start Date: #{test_data["page4"]["timeline"]["start_date"]} (convert to YYYY-MM-DD)
    End Date: #{test_data["page4"]["timeline"]["end_date"]} (convert to YYYY-MM-DD)
    Agreement: Must check the agreement checkbox

    IMPORTANT NOTES:
    - Expand all collapsible sections to access hidden fields
    - Use search functionality for product and vendor tables
    - Items are hidden until you search - pagination shows max 5 results
    - Random popup modals may appear - close them to continue
    - Select project type BEFORE selecting framework
    """
  end

  @doc """
  Executes a test scenario by number (1-3).

  ## Examples

      # Run easiest test
      CuaApp.ChallengeTest.run_scenario(3)

      # Run hardest test
      CuaApp.ChallengeTest.run_scenario(1)
  """
  def run_scenario(scenario_number) when scenario_number in 1..3 do
    IO.puts("Loading test scenario #{scenario_number}...")

    test_data = load_test_data(scenario_number)
    task_description = build_task_description(test_data)

    IO.puts("Test ID: #{test_data["test_id"]}")
    IO.puts("Description: #{test_data["description"]}")
    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Executing task...\n")

    # Execute the agent task
    result = CuaApp.Agent.execute_task(task_description)

    IO.puts("\n" <> String.duplicate("=", 80))
    IO.puts("Test scenario #{scenario_number} completed!")

    result
  end

  @doc """
  Runs all test scenarios in order of difficulty (easy to hard).
  """
  def run_all_scenarios do
    scenarios = [
      {3, "Easy"},
      {2, "Medium"},
      {1, "Hard"}
    ]

    results = Enum.map(scenarios, fn {num, difficulty} ->
      IO.puts("\n" <> String.duplicate("=", 80))
      IO.puts("Starting Scenario #{num} - Difficulty: #{difficulty}")
      IO.puts(String.duplicate("=", 80) <> "\n")

      result = run_scenario(num)

      {num, difficulty, result}
    end)

    # Print summary
    IO.puts("\n\n" <> String.duplicate("=", 80))
    IO.puts("TEST SUMMARY")
    IO.puts(String.duplicate("=", 80))

    Enum.each(results, fn {num, difficulty, result} ->
      status = case result do
        {:ok, _} -> "✓ PASSED"
        {:error, _} -> "✗ FAILED"
        _ -> "? UNKNOWN"
      end

      IO.puts("Scenario #{num} (#{difficulty}): #{status}")
    end)

    results
  end

  @doc """
  Parses various date formats to YYYY-MM-DD format.
  This is an example helper function for date conversion.
  """
  def parse_date(date_string) do
    cond do
      # ISO 8601 with timezone: "1992-03-15T00:00:00Z"
      String.contains?(date_string, "T") ->
        date_string
        |> String.split("T")
        |> List.first()

      # DD/MM/YYYY format: "15/07/1990"
      String.contains?(date_string, "/") ->
        [day, month, year] = String.split(date_string, "/")
        "#{year}-#{String.pad_leading(month, 2, "0")}-#{String.pad_leading(day, 2, "0")}"

      # Already YYYY-MM-DD: "1988-11-22"
      true ->
        date_string
    end
  end

  @doc """
  Normalizes phone numbers to XXX-XXX-XXXX format.
  This is an example helper function for phone conversion.
  """
  def normalize_phone(phone_string) do
    # Remove all non-digit characters
    digits = phone_string
      |> String.replace(~r/[^\d]/, "")
      |> String.slice(-10..-1)  # Take last 10 digits (removes country code)

    # Format as XXX-XXX-XXXX
    case String.length(digits) do
      10 ->
        area = String.slice(digits, 0..2)
        prefix = String.slice(digits, 3..5)
        line = String.slice(digits, 6..9)
        "#{area}-#{prefix}-#{line}"

      _ ->
        raise "Invalid phone number: #{phone_string}"
    end
  end

  @doc """
  Maps full country names to dropdown values.
  """
  def map_country(country_name) do
    mappings = %{
      "United States" => "us",
      "USA" => "us",
      "Canada" => "ca",
      "United Kingdom" => "uk",
      "UK" => "uk",
      "Australia" => "au",
      "Germany" => "de",
      "France" => "fr",
      "Japan" => "jp",
      "Brazil" => "br"
    }

    Map.get(mappings, country_name, String.downcase(country_name))
  end
end

# ============================================================================
# USAGE EXAMPLES
# ============================================================================

# Run in IEx:
#
# # Load test data
# test_data = CuaApp.ChallengeTest.load_test_data(1)
#
# # Run single scenario
# CuaApp.ChallengeTest.run_scenario(3)  # Start with easiest
#
# # Run all scenarios
# CuaApp.ChallengeTest.run_all_scenarios()
#
# # Test helper functions
# CuaApp.ChallengeTest.parse_date("1992-03-15T00:00:00Z")
# # => "1992-03-15"
#
# CuaApp.ChallengeTest.normalize_phone("(415) 555-0123")
# # => "415-555-0123"
#
# CuaApp.ChallengeTest.map_country("United States")
# # => "us"
