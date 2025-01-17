
# simulate running in R CMD check
Sys.setenv("_R_CHECK_PACKAGE_NAME_" = "renv")

context <- function(desc) {
  renv_tests_init()
  testthat::context(desc)
}

test_that <- function(desc, code) {

  # clear RENV_PROFILE
  Sys.unsetenv("RENV_PROFILE")

  # skip tests when run on CRAN's macOS machine
  iscran <- !interactive() && !identical(Sys.getenv("NOT_CRAN"), "true")
  testthat::skip_if(iscran && renv_platform_macos())

  oldlibpaths <- .libPaths()
  oldrepos <- getOption("repos")

  repopath <- getOption("renv.tests.repopath")
  oldrepofiles <- list.files(
    path = repopath,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE
  )

  olduserdir <- file.path(renv_bootstrap_user_dir(), "library")
  olduserfiles <- list.files(
    path       = olduserdir,
    all.files  = TRUE,
    full.names = TRUE,
    no..       = TRUE
  )

  call <- sys.call()
  call[[1]] <- quote(testthat::test_that)
  eval(call, envir = parent.frame())

  newlibpaths <- .libPaths()
  reporter <- testthat::get_reporter()

  ok <-
    identical(reporter$.context, "Sandbox") ||
    identical(oldlibpaths, newlibpaths)

  if (!ok) {
    writeLines(c("", oldlibpaths, "", newlibpaths))
    stopf("test %s has corrupted libpaths", shQuote(desc))
  }

  newrepos <- getOption("repos")
  ok <- identical(oldrepos, newrepos)
  if (!ok) {
    writeLines(c("", oldrepos, "", newrepos))
    stopf("test %s has corrupted repos", shQuote(desc))
  }

  newrepofiles <- list.files(
    path = repopath,
    all.files = TRUE,
    full.names = TRUE,
    recursive = TRUE
  )

  if (!setequal(oldrepofiles, newrepofiles)) {
    writeLines(setdiff(oldrepofiles, newrepofiles))
    writeLines(setdiff(newrepofiles, oldrepofiles))
    stopf("test %s has corrupted packages in repository", shQuote(desc))
  }

  newuserfiles <- list.files(
    path       = olduserdir,
    all.files  = TRUE,
    full.names = TRUE,
    no..       = TRUE
  )

  if (!setequal(olduserfiles, newuserfiles)) {
    writeLines(setdiff(olduserfiles, newuserfiles))
    writeLines(setdiff(newuserfiles, olduserfiles))
    stopf("test %s did not clean up in user cache directory", shQuote(desc))
  }

}

expect_error <- function(...) {
  renv_scope_options(renv.tests.verbose = FALSE)
  testthat::expect_error(...)
}

expect_warning <- function(...) {
  renv_scope_options(renv.tests.verbose = FALSE)
  testthat::expect_warning(...)
}
