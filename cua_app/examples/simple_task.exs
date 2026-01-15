#!/usr/bin/env elixir

# Example: Simple browser automation task
# Run with: elixir examples/simple_task.exs

# This example demonstrates a simple form-filling task
task = """
Navigate to https://example.com/contact-form
Fill out the form with the following information:
- Name: John Doe
- Email: john.doe@example.com
- Subject: Test Inquiry
- Message: This is a test message from the CUA agent.

After filling the form, click the submit button.
"""

IO.puts("Starting CUA Agent...")
IO.puts("Task: #{task}\n")

case CuaApp.run(task, max_iterations: 30) do
  {:ok, result} ->
    IO.puts("\nTask completed successfully!")
    IO.puts("Result: #{result}")

  {:error, reason} ->
    IO.puts("\nTask failed!")
    IO.puts("Reason: #{inspect(reason)}")
end
