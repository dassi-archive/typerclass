# Check to be performed before each commit -------------------------------------

# Format code
# Open the VSCode command palette (Ctrl+Shift+P or Cmd+Shift+P) and run
# "Air: Format Workspace Folder"

# > IMPORTANT: to rebuild the model, open the vignette "model_training.qmd" and
# run all code chunks.

# Load all package functions
devtools::load_all()

# Update documentation
devtools::document()

# Run tests
devtools::test()

# Run package checks
devtools::check()

# Generate test coverage report
covr::package_coverage() # or covr::report() to view in browser

# Build source package
tmp_folder <- tempdir()
pkg_file <- devtools::build(path = tmp_folder)

# Insert package into DASSI repository
REPO_FOLDER <- "/Users/domingo.scisci/Codice/dassi-services/web/dassiRepository/dassi"
SERVER_FOLDER <- "domingo@dassi-services:/home/domingo/dassi-services/web/repository/"

drat::insertPackage(file = pkg_file, repodir = REPO_FOLDER)

# Sync repository
system(
  sprintf(
    "rsync -avz --delete --exclude='.DS_Store' '%s/' '%s'",
    REPO_FOLDER,
    SERVER_FOLDER
  )
)
