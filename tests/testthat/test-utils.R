
context("Utils")

test_that("common utils work as expected", {
  expect_equal(NULL %NULL% 42, 42)
  expect_equal(lines(1, 2, 3), "1\n2\n3")

  if (nzchar(Sys.which("git")))
    expect_equal(git(), Sys.which("git"))
  else
    expect_error(git())
})

test_that("versions are compared as expected", {

  expect_equal(renv_version_compare("0.1.0", "0.2.0"), -1L)
  expect_equal(renv_version_compare("0.2.0", "0.2.0"), +0L)
  expect_equal(renv_version_compare("0.3.0", "0.2.0"), +1L)

})

test_that("inject inserts text at expected anchor point", {

  text <- c("alpha", "beta", "gamma")

  injected <- inject(text, "beta", "BETA")
  expect_equal(injected, c("alpha", "BETA", "gamma"))

  injected <- inject(text, "BETA", "BETA", "beta")
  expect_equal(injected, c("alpha", "beta", "BETA", "gamma"))

})

test_that("aliased_path() correctly forms aliased path", {
  path <- "~/some/path"
  expanded <- path.expand(path)
  expect_equal(path, aliased_path(expanded))
})

test_that("memoize avoids evaluating expression multiple times", {

  envir <- new.env(parent = emptyenv())
  key <- "test"

  value <- 0
  memoize(key, { value <- value + 1 }, envir)
  memoize(key, { value <- value + 1 }, envir)

  expect_equal(envir$test, 1)
  expect_equal(value, 1)

})

test_that("sink captures both stdout and stderr", {

  file <- tempfile("renv-sink-", fileext = ".log")

  osinks <- sink.number(type = "output")
  msinks <- sink.number(type = "message")

  local({
    renv_scope_sink(file)
    writeLines("stdout", con = stdout())
    writeLines("stderr", con = stderr())
  })

  contents <- readLines(file)
  expect_equal(contents, c("stdout", "stderr"))

  expect_equal(sink.number(type = "output"),  osinks)
  expect_equal(sink.number(type = "message"), msinks)


})

test_that("find() returns first non-null matching value", {

  data <- list(x = 1, y = 2, z = 3)

  value <- find(data, function(datum) {
    if (datum == 2)
      return(42)
  })
  expect_equal(value, 42)

  value <- find(data, function(datum) {
    if (datum == 4)
      return(42)
  })
  expect_null(value)

})

test_that("recursing() reports if we're recursing", {

  f <- function(i) {

    if (recursing())
      expect_true(i == 2)
    else
      expect_true(i == 1)


    if (i < 2)
      f(i + 1)

    if (recursing())
      expect_true(i == 2)
    else
      expect_true(i == 1)

  }

  f(1)


})

