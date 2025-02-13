#' @title Find possible transformation of response variables
#' @name find_transformation
#'
#' @description This functions checks whether any transformation, such as log-
#'   or exp-transforming, was applied to the response variable (dependent
#'   variable) in a regression formula. Currently, following patterns are
#'   detected: `log`, `log1p`, `log2`, `log10`, `exp`, `expm1`, `sqrt`,
#'   `log(x+<number>)`, `log-log` and `power` (to 2nd power, like `I(x^2)`).
#'
#' @param x A regression model.
#' @return A string, with the name of the function of the applied transformation.
#'   Returns `"identity"` for no transformation, and e.g. `"log(x+3)"` when
#'   a specific values was added to the response variables before
#'   log-transforming. For unknown transformations, returns `NULL`.
#'
#' @examples
#' # identity, no transformation
#' model <- lm(Sepal.Length ~ Species, data = iris)
#' find_transformation(model)
#'
#' # log-transformation
#' model <- lm(log(Sepal.Length) ~ Species, data = iris)
#' find_transformation(model)
#'
#' # log+2
#' model <- lm(log(Sepal.Length + 2) ~ Species, data = iris)
#' find_transformation(model)
#' @export
find_transformation <- function(x) {
  # sanity check
  if (is.null(x) || is.data.frame(x) || !is_model(x)) {
    return(NULL)
  }

  rv <- find_terms(x)[["response"]]
  transform_fun <- "identity"


  # log-transformation

  if (any(grepl("log\\((.*)\\)", rv))) {
    # do we have log-log models?
    if (grepl("log\\(log\\((.*)\\)\\)", rv)) {
      transform_fun <- "log-log"
    } else {
      # 1. try: log(x + number)
      plus_minus <- tryCatch(
        eval(parse(text = gsub("log\\(([^,\\+)]*)(.*)\\)", "\\2", rv))),
        error = function(e) NULL
      )
      # 2. try: log(number + x)
      if (is.null(plus_minus)) {
        plus_minus <- tryCatch(
          eval(parse(text = gsub("log\\(([^,\\+)]*)(.*)\\)", "\\1", rv))),
          error = function(e) NULL
        )
      }
      if (is.null(plus_minus)) {
        transform_fun <- "log"
      } else {
        transform_fun <- paste0("log(x+", plus_minus, ")")
      }
    }
  }


  # log1p-transformation

  if (any(grepl("log1p\\((.*)\\)", rv))) {
    transform_fun <- "log1p"
  }


  # expm1-transformation

  if (any(grepl("expm1\\((.*)\\)", rv))) {
    transform_fun <- "expm1"
  }


  # log2/log10-transformation

  if (any(grepl("log2\\((.*)\\)", rv))) {
    transform_fun <- "log2"
  }

  if (any(grepl("log10\\((.*)\\)", rv))) {
    transform_fun <- "log10"
  }


  # exp-transformation

  if (any(grepl("exp\\((.*)\\)", rv))) {
    transform_fun <- "exp"
  }


  # sqrt-transformation

  if (any(grepl("sqrt\\((.*)\\)", rv))) {
    plus_minus <- eval(parse(text = gsub("sqrt\\(([^,\\+)]*)(.*)\\)", "\\2", rv)))
    if (is.null(plus_minus)) {
      transform_fun <- "sqrt"
    } else {
      transform_fun <- paste0("sqrt(x+", plus_minus, ")")
    }
  }


  # (unknown) I-transformation

  if (any(grepl("I\\((.*)\\)", rv))) {
    transform_fun <- NULL
  }


  # power-transformation

  if (any(grepl("I\\((.*)\\^\\s*2\\)", rv))) {
    transform_fun <- "power"
  }

  transform_fun
}
