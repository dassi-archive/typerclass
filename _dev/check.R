# Check to be performed before each commit -------------------------------------

# Format code
# Open the VSCode command palette (Ctrl+Shift+P or Cmd+Shift+P) and run
# "Air: Format Workspace Folder"

# Update documentation
devtools::document()

# Run package checks
devtools::check()

# Generate test coverage report
covr::package_coverage() # or covr::report() to view in browser
