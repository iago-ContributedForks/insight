skip_on_os(os = "mac")

test_that("lme4", {
  requiet("lme4")
  data("cbpp", package = "lme4")
  set.seed(123)
  cbpp$cont <- rnorm(nrow(cbpp))
  m <- glmer(cbind(incidence, size - incidence) ~ poly(cont, 2) + (1 | herd),
    data = cbpp, family = binomial
  )
  expect_s3_class(get_data(m), "data.frame")
})


test_that("lm", {
  set.seed(1023)
  x <- rnorm(1000, sd = 4)
  y <- cos(x) + rnorm(1000)
  # fails if we assign this locally
  dat <<- data.frame(x, y)
  mod1 <- lm(y ~ x, data = dat)
  mod2 <- lm(y ~ cos(x), data = dat)
  expect_equal(get_data(mod1), get_data(mod2), ignore_attr = TRUE)
  expect_equal(get_data(mod1)$x, dat$x, ignore_attr = TRUE)
  expect_equal(get_data(mod2)$x, dat$x, ignore_attr = TRUE)
})


test_that("get_data include weights, even if ones", {
  set.seed(123)
  y <- rnorm(100)
  x <- rnorm(100)
  wn <- runif(100)
  w1 <- rep(1, 100)

  #Model with nonuniform weights
  fn <- lm(y ~ x, weights = wn)
  expect_equal(colnames(get_data(fn)), c("y", "x", "(weights)", "wn"))

  #Model with weights equal to 1
  f1 <- lm(y ~ x, weights = w1)
  expect_equal(colnames(get_data(f1)), c("y", "x", "(weights)", "w1"))

  #Model with no weights
  f0 <- lm(y ~ x)
  expect_equal(colnames(get_data(f0)), c("y", "x"))

  # check get_weights still works
  expect_null(get_weights(f0))
  expect_equal(get_weights(f0, null_as_ones = TRUE), w1)
})


test_that("lm with transformations", {
  d <- data.frame(
    time = as.factor(c(1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5)),
    group = c(1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2),
    sum = c(0, 5, 10, 15, 20, 0, 20, 25, 45, 50, 0, 5, 10, 15, 20, 0, 20, 25, 45, 50, 0, 5, 10, 15, 20, 0, 20, 25, 45, 50)
  )
  m <- lm(log(sum + 1) ~ as.numeric(time) * group, data = d)
  expect_equal(colnames(get_data(m)), c("sum", "time", "group"))
})


test_that("lm with poly and NA in response", {
  data(iris)
  d <- iris
  d[1:25, "Sepal.Length"] <- NA
  d2 <<- d
  m <- lm(Sepal.Length ~ Species / poly(Petal.Width, 2), data = d2)
  expect_equal(get_data(m), iris[26:150, c("Sepal.Length", "Species", "Petal.Width")], ignore_attr = TRUE)
})


test_that("mgcv", {
  ## NOTE check back every now and then and see if tests still work
  skip("works interactively")
  requiet("mgcv")
  d <- iris
  d$NewFac <- rep(c(1, 2), length.out = 150)
  model <- gam(Sepal.Length ~ s(Petal.Length, by = interaction(Species, NewFac)), data = d)
  expect_equal(
    head(insight::get_data(model)),
    head(d[c("Sepal.Length", "Petal.Length", "Species", "NewFac")]),
    ignore_attr = TRUE
  )
})

test_that("lm with poly and NA in response", {
  s1 <- summary(iris$Sepal.Length)
  model <- lm(Petal.Length ~ log(Sepal.Width) + Sepal.Length,
    data = iris
  )
  # Same min-max
  s2 <- summary(insight::get_data(model)$Sepal.Length)

  model <- lm(Petal.Length ~ log(1 + Sepal.Width) + Sepal.Length,
    data = iris
  )
  s3 <- summary(insight::get_data(model)$Sepal.Length)

  model <- lm(Petal.Length ~ log(Sepal.Width + 1) + Sepal.Length,
    data = iris
  )
  s4 <- summary(insight::get_data(model)$Sepal.Length)

  model <- lm(Petal.Length ~ log1p(Sepal.Width) + Sepal.Length,
    data = iris
  )
  s5 <- summary(insight::get_data(model)$Sepal.Length)

  expect_equal(s1, s2, tolerance = 1e-4)
  expect_equal(s1, s3, tolerance = 1e-4)
  expect_equal(s1, s4, tolerance = 1e-4)
  expect_equal(s1, s5, tolerance = 1e-4)
  expect_equal(s2, s3, tolerance = 1e-4)
  expect_equal(s2, s4, tolerance = 1e-4)
  expect_equal(s2, s5, tolerance = 1e-4)
  expect_equal(s3, s4, tolerance = 1e-4)
  expect_equal(s3, s5, tolerance = 1e-4)
  expect_equal(s4, s5, tolerance = 1e-4)
})


.runThisTest <- Sys.getenv("RunAllinsightTests") == "yes"
.runStanTest <- Sys.getenv("RunAllinsightStanTests") == "yes"

if (.runThisTest) {
  data(iris)
  m <- lm(Sepal.Length ~ Sepal.Width, data = iris)
  out <- get_data(m)
  test_that("subsets", {
    expect_false(attributes(out)$is_subset)
    expect_equal(colnames(out), c("Sepal.Length", "Sepal.Width"))
    expect_equal(nrow(out), 150)
  })

  m <- lm(Sepal.Length ~ Sepal.Width, data = iris, subset = Species == "versicolor")
  out <- get_data(m)
  test_that("subsets", {
    expect_true(attributes(out)$is_subset)
    expect_equal(colnames(out), c("Sepal.Length", "Sepal.Width", "Species"))
    expect_equal(nrow(out), 50)
  })

  # d <- iris
  # m <- lm(Petal.Length ~ poly(Sepal.Length), data = d)
  # d <<- mtcars
  # expect_warning(expect_warning(out <- get_data(m)))
  # expect_equal(colnames(out), c("Petal.Length", "Sepal.Length"))

  data(iris)
  m <- lm(log(Sepal.Length) ~ sqrt(Sepal.Width), data = iris)
  out <- get_data(m)
  test_that("log", {
    expect_equal(out, iris[c("Sepal.Length", "Sepal.Width")], ignore_attr = TRUE)
  })

  m <- lm(log(Sepal.Length) ~ scale(Sepal.Width), data = iris)
  out <- get_data(m)
  test_that("log", {
    expect_equal(out, iris[c("Sepal.Length", "Sepal.Width")], ignore_attr = TRUE)
  })


  # workaround bug in estimatr
  if (requiet("ivreg") && requiet("estimatr")) {
    data("CigaretteDemand")
    m <- estimatr::iv_robust(
      log(packs) ~ log(rprice) + log(rincome) | salestax + log(rincome),
      data = CigaretteDemand
    )
    out <- get_data(m)
    test_that("estimatr works", {
      expect_equal(
        head(out$packs),
        c(101.08543, 111.04297, 71.95417, 56.85931, 82.58292, 79.47219),
        tolerance = 1e-3
      )
      expect_equal(
        colnames(out),
        c("packs", "rprice", "rincome", "salestax"),
        tolerance = 1e-3
      )
    })
  }


  if (.runStanTest) {
    requiet("brms")
    m <- suppressWarnings(brms::brm(mpg ~ hp + mo(cyl), data = mtcars, refresh = 0, iter = 200, chains = 1))
    out <- get_data(m)
    expect_equal(attributes(out)$factors, "cyl")
    expect_type(out$cyl, "double")
    expect_equal(colnames(out), c("mpg", "hp", "cyl"))

    out <- get_datagrid(m)
    expect_equal(dim(out), c(10, 2))
    expect_equal(out$cyl, c(4, 4, 6, 6, 8, 8, 8, 8, 8, 8))
  }
}

mod <- lm(mpg ~ as.logical(am) + factor(cyl) + as.factor(gear), mtcars)
out <- get_data(mod)
test_that("logicals", {
  expect_equal(out$am, mtcars$am, ignore_attr = TRUE)
})
